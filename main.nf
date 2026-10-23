nextflow.enable.dsl = 2
include { validateParameters; paramsHelp } from 'plugin/nf-schema'
include { SCEPTRE } from './subworkflows/local/sceptre/main'
include { SCEPTREDEMOINPUT as SCEPTRE_DEMO_INPUT } from './modules/local/sceptredemoinput/main'

// Nextflow configFiles omits nested includeConfig files. Resolve a conservative,
// local literal include closure ourselves; reject dynamic includes rather than
// allowing an execution-config change to evade the publication identity.
def configVisit(path, seen) {
    path = path.toAbsolutePath().normalize()
    if (!seen.add(path)) return
    if (!java.nio.file.Files.isRegularFile(path))
        error 'Configuration identity requires readable local configuration files.'
    def source = path.text
    // Inspect keywords outside comments and quoted strings. Literal includes can
    // occur inside an inline profile block; line anchoring would reject those.
    def tokens = (source =~ /(?s)\/\*.*?\*\/|\/\/[^\r\n]*|'(?:\\.|[^'\\])*'|"(?:\\.|[^"\\])*"|\bincludeConfig\b/)
    tokens.results().toList().each { token ->
        if (token.group().startsWith('"')) {
            if (token.group().contains('$') && token.group().contains('includeConfig'))
                error 'Configuration identity cannot inspect includeConfig inside string interpolation.'
        }
        if (token.group() == 'includeConfig') {
            def argument = (source.substring(token.end()) =~ /^\s*(?:\(\s*(['"])([^'"\\\r\n$]+)\1\s*\)|(['"])([^'"\\\r\n$]+)\3)(?!\s*\+)(?=\s*(?:[;}]|\r?\n|$|\/\/|\/\*))/)
            if (!argument.find())
                error 'Configuration identity supports only literal local includeConfig paths (without interpolation or expressions). Rewrite dynamic includes as literal configuration files before running.'
            // Comments are whitespace, not a statement boundary: never accept
            // a literal prefix when a concatenation follows a comment/newline.
            def remainder = source.substring(token.end() + argument.end())
                .replaceFirst(/(?s)^(?:\s|\/\*.*?\*\/|\/\/[^\r\n]*)*/, '')
            if (['.', '+', '-', '*', '/', '%', '?', '[', '<', '>', '=', '!', '&', '|', '^', ':'].any { marker -> remainder.startsWith(marker) } ||
                (remainder =~ /^(?:as|in|instanceof)\b/).find())
                error 'Configuration identity supports only literal local includeConfig paths (without interpolation or expressions). Rewrite dynamic includes as literal configuration files before running.'
            def child = java.nio.file.Paths.get(argument.group(2) ?: argument.group(4))
            if (!child.isAbsolute()) child = path.parent.resolve(child)
            configVisit(child, seen)
        }
    }
}

def configClosure(List roots) {
    def seen = new LinkedHashSet()
    roots.each { root -> configVisit(root, seen) }
    seen.toList().sort { entry -> entry.toString() }
}

// Hash local SIF images in bounded memory before any task is admitted.
def imageSha256(java.nio.file.Path path) {
    def digest = java.security.MessageDigest.getInstance('SHA-256')
    new java.security.DigestInputStream(java.nio.file.Files.newInputStream(path), digest).withCloseable { stream ->
        stream.transferTo(java.io.OutputStream.nullOutputStream())
    }
    digest.digest().encodeHex().toString()
}

workflow {
    if (params.help) {
        log.info 'nextflow run . --input_bundle BUNDLE --analysis_config CONFIG --environment_lock LOCK --outdir RESULTS'
        log.info paramsHelp()
    } else {
        if (params.input && params.input_bundle && file(params.input).toAbsolutePath().normalize() != file(params.input_bundle).toAbsolutePath().normalize())
            error '--input and --input_bundle name different certified bundles; supply one input.'
        def selectedInput = params.input_bundle ?: params.input
        def demoInput = params.test_data && !selectedInput && !params.analysis_config && !params.environment_lock
        if (!demoInput && (!selectedInput || !params.analysis_config || !params.environment_lock))
            error 'Provide a certified --input/--input_bundle, --analysis_config and --environment_lock together; a zero-input -profile test run uses synthetic data.'
        validateParameters()
        def profiles = workflow.profile.tokenize(',')
        log.info "Selected profiles: ${workflow.profile}; scientific execution mode: ${params.execution_mode}."
        log.info 'The default task executor is local. Distributed mode partitions scientific work; scheduler selection comes from profiles/site configuration. Verify executor overrides before running on a cluster login node (docs/hpc.md, docs/recovery.md).'
        if (profiles.any { profile -> profile in ['docker','apptainer'] } && !params.container_image)
            error 'The docker/apptainer profiles require --container_image.'
        if (params.worker_arrays && !profiles.contains('slurm'))
            error 'worker_arrays requires the slurm profile; local execution must not enable scheduler arrays.'
        def immutableOci = params.container_image && (params.container_image ==~ /[A-Za-z0-9._:\/-]+@sha256:[a-f0-9]{64}/ || params.container_image ==~ /sha256:[a-f0-9]{64}/)
        if (params.container_image && !immutableOci) {
            if (!params.container_image.endsWith('.sif'))
                error 'container_image must be an immutable image digest (registry/name@sha256:... or local sha256:...), or an absolute checksum-qualified .sif path under the apptainer profile.'
            if (!profiles.contains('apptainer') || profiles.contains('docker'))
                error 'SIF images require the apptainer profile without the docker profile.'
            def sif = java.nio.file.Paths.get(params.container_image)
            if (!sif.isAbsolute()) error 'SIF path must be absolute.'
            if (!java.nio.file.Files.isRegularFile(sif)) error 'SIF path must name an existing regular .sif file.'
            if (!params.container_image_sha256) error 'container_image_sha256 is required for a local SIF image.'
            if (imageSha256(sif) != params.container_image_sha256) error 'SIF SHA256 mismatch: container bytes differ from container_image_sha256.'
        } else if (params.container_image_sha256) {
            error 'container_image_sha256 applies only to local SIF images.'
        }
        def selected = params.analyses ? params.analyses.split(',').toList() : []
        if (selected.toSet().size() != selected.size() || selected.any { family -> !(family in ['calibration','power','discovery']) })
            error 'analyses must contain unique comma-separated calibration,power,discovery names, or an empty string.'
        def signature = file("${params.outdir}/run_signature.rds")
        def occupied = ['parameters','assignment','qc','calibration','power','discovery','exports'].any { stage ->
            file("${params.outdir}/${stage}").exists()
        }
        if (occupied && !signature.exists())
            error 'Output directory already contains scientific outputs without a compatible run signature. Use a fresh --outdir.'
        // Bind production workflow/module/config/helper bytes, including resolved
        // external configuration files. Keep order stable across checkout relocation.
        def projectSources = ([file("${projectDir}/main.nf"), file("${projectDir}/nextflow.config"),
            file("${projectDir}/nextflow_schema.json"), file("${projectDir}/demo/make-input.R")] +
            files("${projectDir}/bin/*.R") + files("${projectDir}/conf/*.config") +
            files("${projectDir}/modules/**/*.nf") + files("${projectDir}/subworkflows/**/*.nf"))
            .flatten().unique().sort { source -> source.toString() }
        def externalConfigs = configClosure(workflow.configFiles).findAll { source -> !(source in projectSources) }
        // External site configuration may contain credentials: bind its bytes
        // without mounting or copying it into an R worker/container.
        def externalConfigDigests = externalConfigs.collect { source ->
            java.security.MessageDigest.getInstance('SHA-256').digest(source.bytes).encodeHex().toString()
        }
        def runOptions = groovy.json.JsonOutput.toJson([
            session_id: workflow.sessionId.toString(), external_config_sha256: externalConfigDigests, analyses: selected, stop_after: params.stop_after, checkpoint_stage: params.checkpoint_stage,
            seed: params.seed, container_image: params.container_image, container_image_sha256: params.container_image_sha256, execution_mode: params.execution_mode, n_work_units: params.n_work_units, array_size: params.array_size, worker_arrays: params.worker_arrays
        ])
        channel.topic('versions')
            .map { process, tool, version -> "${groovy.json.JsonOutput.toJson(process)}:\n  ${tool}: ${groovy.json.JsonOutput.toJson(version.toString().trim())}" }
            .unique()
            .collectFile(name: 'software_versions.yml', storeDir: "${params.outdir}/pipeline_info", sort: true, newLine: true)
        if (demoInput) {
            log.info 'Synthetic demonstration: no experimental input supplied. Generating source-pinned counts in the selected runtime.'
            SCEPTRE_DEMO_INPUT(channel.value(file("${projectDir}/bin", checkIfExists: true)), channel.value(file("${projectDir}/demo", checkIfExists: true)))
            inputState = SCEPTRE_DEMO_INPUT.out.fixture.map { fixture -> tuple([id: 'synthetic-screen'], fixture.resolve('input')) }
            inputConfig = SCEPTRE_DEMO_INPUT.out.fixture.map { fixture -> fixture.resolve('config.rds') }
            inputLock = SCEPTRE_DEMO_INPUT.out.fixture.map { fixture -> fixture.resolve('lock.rds') }
        } else {
            inputState = channel.value(tuple([id: 'screen'], file(selectedInput, checkIfExists: true)))
            inputConfig = channel.value(file(params.analysis_config, checkIfExists: true))
            inputLock = channel.value(file(params.environment_lock, checkIfExists: true))
        }
        SCEPTRE(
            inputState,
            inputConfig,
            inputLock,
            channel.value(file(params.backing_directory, checkIfExists: true)),
            channel.value(file("${projectDir}/bin", checkIfExists: true)),
            channel.value(signature.exists() ? signature : file("${projectDir}/resources/no_previous_run.rds")),
            runOptions, channel.value(projectSources), selected, params.stop_after, params.checkpoint_stage, params.seed, params.execution_mode, params.n_work_units
        )
    }
}
