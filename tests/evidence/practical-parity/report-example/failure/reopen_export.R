# Portable schema-7 deliveries. Source this file, then reopen_sceptre_export("export-dir").
# Relocated descriptors are always admitted by the package public reader.
export_count_matrices <- function(object) {
    sce <- sceptre::get_screen_experiment(object)
    list(response = SummarizedExperiment::assay(sce, "counts", withDimnames = FALSE),
        grna = SummarizedExperiment::assay(SingleCellExperiment::altExp(sce, "gRNA", withDimnames = FALSE), "counts", withDimnames = FALSE))
}
export_backing_paths <- function(matrices) lapply(matrices, function(x) {
    paths <- unique(unlist(DelayedArray::seedApply(x, function(seed) {
        if (isS4(seed) && "filepath" %in% methods::slotNames(seed)) {
            if (!(methods::is(seed, "H5SparseMatrixSeed") || methods::is(seed, "HDF5ArraySeed")))
                stop("Unsupported backing seed in portable delivery.")
            as.character(methods::slot(seed, "filepath"))
        } else character()
    }), use.names = FALSE))
    if (length(paths)) paths else character()
})
write_portable_sceptre_export <- function(object, directory) {
    dir.create(directory, recursive = TRUE, showWarnings = FALSE)
    paths <- export_backing_paths(export_count_matrices(object))
    all_paths <- unique(unlist(paths, use.names = FALSE))
    hashes <- vapply(all_paths, function(path) digest::digest(file = path, algo = "sha256"), character(1))
    mapping <- lapply(paths, function(x) if (length(x)) stats::setNames(x, paste0("backing/", unname(hashes[match(x, all_paths)]), ".h5")) else character())
    if (length(all_paths)) dir.create(file.path(directory, "backing"), showWarnings = FALSE)
    for (i in seq_along(all_paths)) {
        dest <- file.path(directory, "backing", paste0(hashes[[i]], ".h5"))
        if (!file.exists(dest) && !file.copy(all_paths[[i]], dest)) stop("Unable to copy immutable backing file.")
        if (!identical(digest::digest(file = dest, algo = "sha256"), hashes[[i]])) stop("Portable backing checksum mismatch.")
    }
    file <- file.path(directory, "sceptre_object.rds")
    sceptre::write_sceptre_object(object, file)
    manifest <- list(kind = "sceptre-pipeline-portable-export", schema = 1L,
        object_schema = object@schema_version, package_version = as.character(utils::packageVersion("sceptre")),
        object_sha256 = digest::digest(file = file, algo = "sha256"), backing_files = mapping,
        backing_sha256 = if (length(hashes)) stats::setNames(unname(hashes), paste0("backing/", hashes, ".h5")) else character())
    saveRDS(manifest, file.path(directory, "portable-manifest.rds"))
    invisible(manifest)
}
reopen_sceptre_export <- function(directory) {
    manifest <- readRDS(file.path(directory, "portable-manifest.rds"))
    if (!identical(manifest$kind, "sceptre-pipeline-portable-export") || !identical(manifest$schema, 1L) ||
        !identical(manifest$object_schema, 7L) || !identical(names(manifest$backing_files), c("response", "grna")))
        stop("Unsupported portable export manifest.")
    file <- file.path(directory, "sceptre_object.rds")
    if (!identical(digest::digest(file = file, algo = "sha256"), manifest$object_sha256)) stop("Portable object checksum mismatch.")
    relative <- names(manifest$backing_sha256)
    if (length(relative) && (anyNA(relative) || any(!grepl("^backing/[a-f0-9]{64}[.]h5$", relative))))
        stop("Malformed portable backing paths.")
    for (path in relative) {
        actual <- file.path(directory, path)
        if (!file.exists(actual) || !identical(digest::digest(file = actual, algo = "sha256"), manifest$backing_sha256[[path]]))
            stop("Missing or corrupt portable backing: ", path)
    }
    saved <- readRDS(file)
    matrices <- export_count_matrices(saved)
    original_paths <- export_backing_paths(matrices)
    for (modality in names(matrices)) {
        mapping <- manifest$backing_files[[modality]]
        if (!identical(unname(mapping), original_paths[[modality]]) ||
            any(!names(mapping) %in% relative)) stop("Portable backing mapping disagrees with saved descriptors.")
        if (!length(mapping)) next
        matrices[[modality]] <- DelayedArray::modify_seeds(matrices[[modality]], function(seed) {
            if (isS4(seed) && "filepath" %in% methods::slotNames(seed)) {
                index <- match(as.character(methods::slot(seed, "filepath")), mapping)
                if (is.na(index)) stop("Unmapped native backing seed.")
                methods::slot(seed, "filepath") <- normalizePath(file.path(directory, names(mapping)[[index]]), mustWork = TRUE)
            }
            seed
        })
    }
    sceptre::read_sceptre_object(file, matrices$response, matrices$grna)
}
