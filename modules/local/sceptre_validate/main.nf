process SCEPTRE_VALIDATE {
    tag "${meta.id}:validate"
    label 'process_single'
    cache false // Check actual runtime even on -resume; scientific tasks remain cacheable.

    input:
    tuple val(meta), path(state, name: 'input_state')
    path config, name: 'analysis_config.rds'
    path lock, name: 'environment_lock.rds'
    path backing, name: 'backing'
    path tools_dir, name: 'pipeline_bin'
    path previous_signature, name: 'previous_signature.rds'
    val run_options
    path implementation_sources, name: 'pipeline_source/file????'

    output:
    val meta, emit: meta
    val true, emit: ready
    path 'run_signature.rds', emit: signature
    path 'resolved_settings.*', emit: settings

    tuple val("${task.process}"), val("sceptre"), eval("Rscript --vanilla pipeline_bin/version-string.R environment_lock.rds"), topic: versions, emit: versions_sceptre

    when:
    task.ext.when == null || task.ext.when || error("Selected certified stages cannot be disabled with ext.when; use --analyses or --stop_after.")

    script:
    """
    Rscript --vanilla pipeline_bin/validate_state.R analysis_config.rds input_state environment_lock.rds backing '${run_options}' previous_signature.rds pipeline_source
    Rscript --vanilla pipeline_bin/versions.R environment_lock.rds
    """
}
