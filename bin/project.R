# Reproducible public-R preparation and configuration interface.
# JSON references are explicit: {"$rds":"path"}, {"$table":"path"},
# {"$formula":"~ batch + z"}; all other values remain ordinary arguments.
project_read_json <- function(path) jsonlite::fromJSON(path, simplifyVector = FALSE)
project_bind_source <- function(path, sources) {
    paths <- unique(c(sources$paths, path))
    if (!is.null(sources$max_source_bytes) && sum(file.info(paths)$size) > sources$max_source_bytes)
        fail('Source bytes exceed resources$max_source_bytes while resolving file references; counts have not been read.')
    digest <- hash_file(path)
    if (!is.null(sources$hashes[[path]]) && !identical(unname(sources$hashes[[path]]), digest)) fail('Source changed while decoding references: ', path)
    sources$paths <- unique(c(sources$paths, path))
    sources$hashes[[path]] <- digest
    invisible(path)
}
project_decode <- function(x, root, sources) {
    if (!is.list(x)) return(x)
    refs <- intersect(names(x), c('$rds', '$table', '$formula'))
    if (length(refs)) {
        table_rows <- length(refs) == 1L && refs == '$table' && length(x) == 2L && setequal(names(x), c('$table','row_names'))
        if (length(refs) != 1L || (!table_rows && length(x) != 1L) || !is.character(x[[refs]]) || length(x[[refs]]) != 1L)
            fail('A reference requires one scalar $rds, $table or $formula key; only $table additionally accepts row_names.')
        if (refs == '$formula') return(stats::as.formula(x[[refs]], env = baseenv()))
        path <- x[[refs]]
        if (!grepl('^/', path)) path <- file.path(root, path)
        path <- normalizePath(path, mustWork = TRUE)
        project_bind_source(path, sources)
        if (refs == '$rds') return(readRDS(path))
        table <- utils::read.delim(path, check.names = FALSE, stringsAsFactors = FALSE)
        if (table_rows) {
            key <- x$row_names
            if (!is.character(key) || length(key) != 1L || !key %in% names(table)) fail('row_names must name an existing table column.')
            ids <- as.character(table[[key]])
            if (anyNA(ids) || any(!nzchar(ids)) || anyDuplicated(ids)) fail('row_names IDs must be unique and nonmissing.')
            rownames(table) <- ids; table[[key]] <- NULL
        }
        return(table)
    }
    out <- lapply(x, project_decode, root = root, sources = sources)
    # JSON arrays of scalars are R vectors; named objects remain argument lists.
    if (is.null(names(x)) && length(out) && all(vapply(out, function(v) !is.list(v) && length(v) == 1L, logical(1))))
        return(unlist(out, use.names = FALSE))
    out
}
project_arguments <- function(args, fun, label, excluded = character()) {
    if (!is.list(args) || (length(args) && (is.null(names(args)) || anyDuplicated(names(args)) || any(!nzchar(names(args))))))
        fail(label, ' must be a named argument list.')
    allowed <- setdiff(names(formals(fun)), c('sceptre_object', excluded))
    bad <- setdiff(names(args), allowed)
    if (length(bad)) fail('Unsupported ', label, ' arguments: ', paste(bad, collapse = ', '))
    invisible(args)
}
project_directory_inventory <- function(path) {
    files <- list.files(path, recursive = TRUE, full.names = TRUE, all.files = TRUE, no.. = TRUE)
    sort(files[!dir.exists(files)])
}
project_file_sources <- function(args, names, sources, root) {
    for (name in intersect(names, names(args))) {
        paths <- args[[name]]
        if (!is.character(paths) || !length(paths) || anyNA(paths)) fail(name, ' must name local files/directories.')
        paths <- vapply(paths, function(path) normalizePath(if (grepl('^/', path)) path else file.path(root, path), mustWork = TRUE), character(1))
        args[[name]] <- paths
        for (path in paths) {
            if (dir.exists(path)) sources$directories <- unique(c(sources$directories, path))
            else sources$paths <- unique(c(sources$paths, path))
        }
    }
    args
}
project_named <- function(value, label, allowed) {
    if (!is.list(value) || (length(value) && (is.null(names(value)) || anyNA(names(value)) || any(!nzchar(names(value))) || anyDuplicated(names(value)))) || any(!names(value) %in% allowed))
        fail(label, ' must be a named list with unique supported keys: ', paste(allowed, collapse = ', '))
    invisible(value)
}
project_pairs <- function(object, config, spec) {
    if (is.null(spec)) return(config)
    project_named(spec, 'pairs', c('discovery', 'positive_control'))
    if (is.null(config$analysis)) config$analysis <- list()
    for (family in c('positive_control', 'discovery')) {
        request <- spec[[family]]
        if (is.null(request)) next
        field <- if (family == 'discovery') 'discovery_pairs' else 'positive_control_pairs'
        if (!is.null(config$analysis[[field]])) fail('Specify ', field, ' in analysis or pairs, not both.')
        project_named(request, 'pair constructor request', c('method','arguments','assembly'))
        if (!is.character(request$method) || length(request$method) != 1L || is.na(request$method)) fail('Pair constructor requires one method.')
        method <- request$method
        fun <- switch(method, cis = sceptre::construct_cis_pairs, trans = sceptre::construct_trans_pairs,
            positive_control = sceptre::construct_positive_control_pairs, fail('Unknown pair constructor: ', method))
        if (family == 'positive_control' && method != 'positive_control') fail('positive_control construction requires method positive_control; explicit tables belong in analysis.')
        args <- if (is.null(request$arguments)) list() else request$arguments
        project_arguments(args, fun, paste(family, 'pair constructor'))
        if (method == 'cis' && (is.null(args$response_position_data_frame) || is.null(request$assembly) ||
            !is.character(request$assembly) || length(request$assembly) != 1L || !nzchar(request$assembly)))
            fail('cis construction requires explicit frozen response_position_data_frame and assembly label; no implicit genome annotation.')
        if (method %in% c('cis','trans') && is.null(args$positive_control_pairs) && !is.null(config$analysis$positive_control_pairs))
            args$positive_control_pairs <- config$analysis$positive_control_pairs
        result <- do.call(fun, c(list(sceptre_object = object), args))
        if (!nrow(result)) fail('Pair constructor produced an empty ', family, ' family.')
        config$analysis[[field]] <- result
    }
    config
}
project_settings_value <- function(x) {
    if (inherits(x,'formula')) return(paste(deparse(x),collapse=' '))
    if (is.data.frame(x)) return(list(rows=nrow(x),columns=names(x),sha256=hash_value(x),preview=utils::head(x,6L)))
    if (is.list(x)) return(lapply(x,project_settings_value))
    if (is.atomic(x) && length(x)>20L) return(list(length=length(x),sha256=hash_value(x),preview=utils::head(x,12L)))
    x
}
project_preflight <- function(object, config, analyses = c('calibration','power','discovery')) {
    validate_object(object); validate_config(config)
    if (anyDuplicated(analyses) || any(!analyses %in% c('calibration','power','discovery'))) fail('Invalid selected analyses.')
    candidate <- if (is.null(config$analysis)) object else do.call(sceptre::set_analysis_parameters, c(list(sceptre_object = object), config$analysis))
    if (pipeline_parameters_pending(candidate)) fail('Supply analysis settings for an unconfigured input.')
    notes <- character()
    if (!is.null(config$analysis) && !all(c('discovery_pairs','positive_control_pairs','formula_object') %in% names(config$analysis)))
        notes <- c(notes, 'analysis is a complete public set_analysis_parameters call: omitted pairs/formula use package defaults, not prior saved settings.')
    if (!pipeline_low_moi(candidate) && identical(config$analysis$control_group, 'nt_cells'))
        notes <- c(notes, 'Requested high-MOI nt_cells resolves to complement in the qualified R package; no NT-control inference is performed.')
    if ('power' %in% analyses && !nrow(candidate@spec@positive_control_pairs)) fail('Selected power analysis requires positive_control_pairs. Remove power from analyses or supply pairs.')
    if ('discovery' %in% analyses && !nrow(candidate@spec@discovery_pairs)) fail('Selected discovery analysis requires discovery_pairs. Remove discovery from analyses or supply pairs.')
    assignment <- config$assignment
    method <- if (is.null(assignment$method)) 'default' else assignment$method
    resolved_method <- if (method == 'default') if (pipeline_low_moi(candidate)) 'maximum' else 'mixture' else method
    if (!resolved_method %in% c('maximum','thresholding','mixture')) fail('Unsupported assignment method: ', method)
    allowed <- switch(resolved_method, maximum = c('method','umi_fraction_threshold','min_grna_n_umis_threshold'),
        thresholding = c('method','threshold'), mixture = c('method','n_em_rep','pi_guess_range','g_pert_guess_range','n_nonzero_cells_cutoff','backup_threshold','probability_threshold','formula_object'))
    bad <- setdiff(names(assignment), allowed)
    if (length(bad)) fail('Assignment arguments incompatible with resolved ', resolved_method, ': ', paste(bad, collapse = ', '))
    spec <- candidate@spec
    resources <- project_resources(candidate, config$resources)
    list(kind = 'sceptre-pipeline-settings', schema = 1L, package = package_identity(),
         requested = project_settings_value(config), config_sha256 = hash_value(config), analyses = analyses, notes = notes, resources = resources,
         resolved = list(moi = if (pipeline_low_moi(candidate)) 'low' else 'high',
            control_group = if (spec@control_group_complement) 'complement' else 'nt_cells',
            resampling_mechanism = if (spec@run_permutations) 'permutations' else 'crt',
            resampling_approximation = spec@resampling_approximation,
            side = c('left','both','right')[spec@side_code + 2L],
            grna_integration_strategy = spec@grna_integration_strategy,
            formula_object = paste(deparse(spec@formula_object), collapse = ' '),
            multiple_testing_alpha = spec@multiple_testing_alpha,
            multiple_testing_method = spec@multiple_testing_method,
            assignment = if (is.null(assignment) && identical(spec@grna_assignment_method, 'external')) 'preserve_external' else resolved_method,
            discovery_pairs = nrow(spec@discovery_pairs), positive_control_pairs = nrow(spec@positive_control_pairs),
            design = hash_value(candidate@preparation@design_matrix)))
}
project_prepare <- function(input_spec, config, output, root = getwd(), source_paths = character(), source_hashes = NULL) {
    if (file.exists(output)) fail('Preparation output already exists: ', output)
    project_named(input_spec, 'input specification', c('method','arguments','pairs','analyses','seed'))
    if (!is.character(input_spec$method) || length(input_spec$method) != 1L || is.na(input_spec$method)) fail('Input specification requires one method.')
    functions <- list(matrix = sceptre::import_data, sce = sceptre::import_from_sce,
        tenx = sceptre::import_data_from_10x, cellranger = sceptre::import_data_from_cellranger,
        parse = sceptre::import_data_from_parse, object = sceptre::read_sceptre_object)
    method <- input_spec$method
    if (!method %in% names(functions)) fail('Unknown import method: ', method)
    fun <- functions[[method]]; args <- if (is.null(input_spec$arguments)) list() else input_spec$arguments
    project_arguments(args, fun, 'import')
    if (method != 'object' && is.null(args$moi)) fail('moi must be explicit in the import specification.')
    sources <- new.env(parent = emptyenv()); sources$paths <- source_paths; sources$directories <- character()
    args <- project_file_sources(args, c('samples','directories','gene_mat_fp','grna_mat_fp','all_genes_fp','all_grnas_fp','file'), sources, root)
    inventory <- lapply(sources$directories, project_directory_inventory)
    sources$paths <- unique(c(sources$paths, unlist(inventory, use.names = FALSE)))
    files <- unique(sources$paths[!dir.exists(sources$paths)])
    hashes <- vapply(files, hash_file, character(1))
    if (length(source_hashes) && (!all(names(source_hashes) %in% names(hashes)) ||
        !identical(unname(unlist(source_hashes, use.names = FALSE)), unname(hashes[names(source_hashes)]))))
        fail('A source changed after reference decoding; no project published.')
    validate_config(config)
    if (!is.null(config$resources$max_source_bytes) && sum(file.info(files)$size) > config$resources$max_source_bytes)
        fail('Source bytes exceed resources$max_source_bytes before import; increase the declared limit or use an explicitly supported backing path.')
    tmp <- tempfile('.project-', tmpdir = dirname(output)); dir.create(tmp)
    on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
    # Package-created native files live under the eventual stable output root;
    # relocate through package persistence before atomic publication below.
    if ('directory_to_write' %in% names(formals(fun))) {
        if (!is.null(args$directory_to_write)) fail('directory_to_write is owned by project preparation; omit it.')
        args$directory_to_write <- file.path(tmp, 'import-backing')
    }
    if (method == 'object') pipeline_assert_native_schema(readRDS(args$file))
    object <- do.call(fun, args)
    validate_object(object)
    config <- project_pairs(object, config, input_spec$pairs)
    analyses <- if (is.null(input_spec$analyses)) c('calibration','power','discovery') else if (!length(input_spec$analyses)) character() else input_spec$analyses
    settings <- project_preflight(object, config, analyses)
    if (!identical(inventory, lapply(sources$directories, project_directory_inventory)) ||
        !identical(hashes, vapply(files, hash_file, character(1)))) fail('A source changed during import; no project published.')
    backing <- file.path(tmp, 'backing'); dir.create(backing)
    map <- pipeline_backing_map(object)
    for (path in unique(unlist(map, use.names = FALSE))) {
        dest <- file.path(backing, paste0(hash_file(path), '.h5'))
        if (!file.exists(dest) && !file.copy(path, dest)) fail('Cannot copy native backing.')
        if (!identical(hash_file(dest), hash_file(path))) fail('Backing copy checksum mismatch.')
    }
    saveRDS(list(kind = 'sceptre-pipeline-native-backing', schema = 1L, object_schema = 7L,
        import_identity = pipeline_import_identity(object), files = map), file.path(backing, 'backing_manifest.rds'))
    lock <- package_identity()
    create_input(object, file.path(tmp,'input'), config, lock)
    saveRDS(config, file.path(tmp,'analysis_config.rds')); saveRDS(lock, file.path(tmp,'environment_lock.rds'))
    saveRDS(settings, file.path(tmp,'settings.rds'))
    jsonlite::write_json(settings, file.path(tmp,'settings.json'), auto_unbox = TRUE, pretty = TRUE, null = 'null', force = TRUE)
    saveRDS(list(kind = 'sceptre-pipeline-preparation', schema = 1L, method = method,
        source_files = hashes, source_directories = stats::setNames(inventory,sources$directories), input_spec_sha256 = hash_value(input_spec), config_sha256 = hash_value(config),
        object_import_identity = pipeline_import_identity(object), package = lock,
        analyses = analyses, pairs = input_spec$pairs), file.path(tmp,'preparation.rds'))
    final <- file.path(normalizePath(dirname(output), mustWork = TRUE), basename(output))
    params <- list(input_bundle = file.path(final,'input'), analysis_config = file.path(final,'analysis_config.rds'),
        environment_lock = file.path(final,'environment_lock.rds'), backing_directory = file.path(final,'backing'),
        analyses = paste(analyses, collapse = ','))
    if (!is.null(input_spec$seed)) {
        seed <- input_spec$seed
        if (!is.numeric(seed) || length(seed) != 1L || is.na(seed) || seed < 0 || seed > .Machine$integer.max || seed != floor(seed)) fail('seed must be a supported nonnegative integer.')
        params$seed <- seed
    }
    jsonlite::write_json(params, file.path(tmp,'params.json'), pretty = TRUE, auto_unbox = TRUE)
    # RDS seed paths refer to staging paths; the manifest binds those source paths
    # and content hashes, enabling read_bundle to substitute stable backing paths.
    unlink(file.path(tmp,'import-backing'), recursive = TRUE)
    if (!file.rename(tmp, output)) fail('Cannot publish prepared project.')
    invisible(settings)
}

# Necessary component sizes, never an invented peak-RAM prediction or method fallback.
project_resources <- function(object, limits = NULL) {
    sce <- sceptre::get_screen_experiment(object)
    design <- object@preparation@design_matrix
    paths <- unique(unlist(pipeline_count_paths(object), use.names = FALSE))
    observed <- list(cells = ncol(sce), responses = nrow(sce),
        requested_pairs = nrow(object@spec@discovery_pairs) + nrow(object@spec@positive_control_pairs),
        design_bytes = as.double(length(design)) * 8,
        backing_bytes = if (length(paths)) sum(file.info(paths)$size) else 0)
    for (key in intersect(names(limits), c('max_cells','max_requested_pairs','max_design_bytes','max_backing_bytes'))) {
        value <- observed[[sub('^max_', '', key)]]
        if (value > limits[[key]]) fail('Resource admission: ', key, ' exceeded (', value, ' > ', limits[[key]], '). Adjust explicit resources/site allocation; scientific settings are never changed automatically.')
    }
    list(observed = observed, limits = limits,
        qualification = 'Necessary payload bounds only; not peak memory or arbitrary-scale admission.',
        policy = 'No automatic changes to method, resampling budget, backend, family, or concurrency. Measure per-stage trace peak RSS and wall time.')
}

project_verify <- function(directory) {
    receipt <- readRDS(file.path(directory,'preparation.rds'))
    if (!identical(receipt$kind,'sceptre-pipeline-preparation') || !identical(receipt$schema,1L) || !'source_directories' %in% names(receipt)) fail('Unsupported preparation receipt.')
    files <- receipt$source_files
    if (!is.character(files) || (length(files) && is.null(names(files))) ||
        !all(file.exists(names(files))) || !identical(files,vapply(names(files),hash_file,character(1))))
        fail('Prepared project source changed or is missing; create a fresh run directory.')
    inventory <- receipt$source_directories
    if (length(inventory) && (!is.list(inventory) || is.null(names(inventory)) ||
        !identical(inventory,lapply(stats::setNames(names(inventory),names(inventory)),project_directory_inventory))))
        fail('Prepared raw directory inventory changed; create a fresh run directory.')
    config <- readRDS(file.path(directory,'analysis_config.rds'))
    if (!identical(receipt$config_sha256,hash_value(config))) fail('Prepared config identity changed.')
    lock <- readRDS(file.path(directory,'environment_lock.rds'));validate_identity(lock)
    if (!identical(receipt$package,lock)) fail('Prepared project runtime changed.')
    state <- read_bundle(file.path(directory,'input'),config,lock,file.path(directory,'backing'))
    if (!identical(receipt$object_import_identity,pipeline_import_identity(state$object))) fail('Prepared project imported identity changed.')
    invisible(receipt)
}
