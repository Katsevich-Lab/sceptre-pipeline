#!/usr/bin/env Rscript
# Bounded integration evidence for scientific delivery, not scale qualification.
source("bin/pipeline.R")
source("bin/distributed.R")
source("bin/scientific_report.R")
source("bin/reopen_export.R")
source("tests/fixture.R")
args <- commandArgs(TRUE)
root <- if (length(args)) args[[1L]] else tempfile("delivery-"); dir.create(root, recursive = TRUE)
expect_error <- function(code, pattern) {
    err <- tryCatch({ force(code); NULL }, error = identity)
    stopifnot(inherits(err, "error"), grepl(pattern, conditionMessage(err)))
}
# Empty native-backing maps must remain character(0), including RAM-only reports.
ram <- pipeline_fixture()
ram_directory <- file.path(root, "ram-portable")
ram_manifest <- write_portable_sceptre_export(ram$object, ram_directory)
stopifnot(length(ram_manifest$backing_sha256) == 0L,
    identical(lapply(export_count_matrices(reopen_sceptre_export(ram_directory)), as.matrix),
        lapply(export_count_matrices(ram$object), as.matrix)))
fixture <- pipeline_fixture(backed = TRUE, directory = file.path(root, "source"))
config <- fixture$config; lock <- package_identity(); seed <- 731L
input <- file.path(root, "input"); create_input(fixture$object, input, config, lock)
for (stage in c("parameters", "assignment", "qc")) {
    output <- file.path(root, stage)
    run_stage(config, input, output, stage, seed, identity = lock)
    input <- output
}
qc <- read_bundle(input, config, lock)$object
qct <- report_pair_qc(qc)
stopifnot(any(!qct$discovery$pass_qc),
    identical(qct$discovery$pass_qc, qc@preparation@discovery_pairs_with_info$pass_qc),
    all(nzchar(qct$discovery$failure_reasons[!qct$discovery$pass_qc])),
    all(!nzchar(qct$discovery$failure_reasons[qct$discovery$pass_qc])))
plan <- file.path(root, "plan")
prepare_distributed(config, input, plan, "discovery", seed, 2L, NULL, lock)
ids <- readLines(file.path(plan, "unit_ids.txt")); proposals <- character()
for (id in ids) {
    path <- file.path(root, paste0(id, ".rds"))
    run_distributed_unit(config, input, plan, path, "discovery", seed, id, NULL, lock)
    proposal <- readRDS(path)
    # Synthetic condition metadata must never enter the package proposal digest.
    attr(proposal, "pipeline_warnings") <- list(list(stage = "discovery", source = "execute_work_unit",
        unit_id = id, message = "delivery fixture warning", class = c("simpleWarning", "warning", "condition")))
    saveRDS(proposal, path); proposals <- c(proposals, path)
}
completed <- file.path(root, "discovery")
collect_distributed(config, input, plan, rev(proposals), completed, "discovery", seed, NULL, lock)
state <- read_bundle(completed, config, lock)
stopifnot(length(state$manifest$warnings) >= length(ids),
    all(ids %in% vapply(state$manifest$warnings, function(x) if (is.null(x$unit_id)) "" else x$unit_id, character(1))))
# Compare actual distributed output to direct public R under the exact RNG history.
direct <- run_stage(config, input, file.path(root, "direct"), "discovery", seed, identity = lock)
stopifnot(identical(sceptre::get_result(state$object, "run_discovery_analysis"),
    sceptre::get_result(direct, "run_discovery_analysis")))
object_hash <- hash_file(file.path(completed, "sceptre_object.rds"))
manifest_hash <- hash_file(file.path(completed, "manifest.rds"))
rng <- .Random.seed
report <- file.path(root, "report")
stopifnot(write_scientific_report_safely(state$object, state$manifest, config, report,
    normalizePath("bin/scientific_report.R")))
stopifnot(identical(rng, .Random.seed))
data <- readRDS(file.path(report, "report-data.rds"))
stopifnot(data$analyses$calibration$status == "omitted", data$analyses$power$status == "omitted",
    data$analyses$discovery$status == "completed", nrow(data$qc$families) == 2L,
    any(grepl("delivery fixture warning", readLines(file.path(report, "warnings.json")))),
    file.exists(file.path(report, "plots", "qc.png")),
    all(vapply(data$plot_status[c("covariates", "grna_counts", "assignment", "qc", "discovery")], function(x) identical(x$status, "completed"), logical(1))))
stopifnot(identical(readRDS(file.path(report, "tables", "qc_discovery.rds")), qct$discovery),
    identical(readRDS(file.path(report, "tables", "discovery.rds")), sceptre::get_result(state$object, "run_discovery_analysis")))
# Plot failure does not suppress independent eligible figures or affect RNG.
plots <- report_scientific_plots(state$object, c("qc", "discovery"), report,
    list(qc = function(x) { runif(1); stop("forced plot failure") },
         discovery = function(x) ggplot2::ggplot(data.frame(x = 1), ggplot2::aes(x, x)) + ggplot2::geom_point()))
stopifnot(plots$status$qc$status == "failed", plots$status$discovery$status == "completed",
    identical(rng, .Random.seed))
failed <- file.path(root, "failed-render")
stopifnot(!write_scientific_report_safely(state$object, state$manifest, config, failed,
    normalizePath("bin/scientific_report.R"), renderer = function(...) stop("forced renderer failure")),
    file.exists(file.path(failed, "portable-manifest.rds")),
    file.exists(file.path(failed, "tables", "discovery.csv")),
    identical(hash_file(file.path(completed, "sceptre_object.rds")), object_hash),
    identical(hash_file(file.path(completed, "manifest.rds")), manifest_hash))
# Move delivery, remove all original backing paths, then reopen via public reader.
relocated <- file.path(root, "relocated")
stopifnot(file.rename(report, relocated))
originals <- unique(unlist(pipeline_count_paths(state$object), use.names = FALSE))
expected <- lapply(export_count_matrices(state$object), as.matrix)
for (path in originals) stopifnot(file.rename(path, paste0(path, ".absent")))
restored <- reopen_sceptre_export(relocated)
stopifnot(identical(lapply(export_count_matrices(restored), as.matrix), expected),
    identical(sceptre::get_result(restored, "run_discovery_analysis"), sceptre::get_result(state$object, "run_discovery_analysis")))
manifest <- readRDS(file.path(relocated, "portable-manifest.rds"))
backing <- file.path(relocated, names(manifest$backing_sha256)[[1L]])
stopifnot(file.rename(backing, paste0(backing, ".absent")))
expect_error(reopen_sceptre_export(relocated), "Missing or corrupt portable backing")
stopifnot(file.rename(paste0(backing, ".absent"), backing))
connection <- file(backing, "ab"); writeBin(as.raw(1L), connection); close(connection)
expect_error(reopen_sceptre_export(relocated), "Missing or corrupt portable backing")
# Even a rewritten transport hash cannot bypass the package's import anchors.
new_hash <- digest::digest(file = backing, algo = "sha256")
manifest$backing_sha256[[1L]] <- new_hash
saveRDS(manifest, file.path(relocated, "portable-manifest.rds"))
expect_error(reopen_sceptre_export(relocated), "backing|Backing|hash|content|changed")
cat("PASS: delivery QC, public plots, warnings, exact distributed/direct results, RNG, failure isolation, relocation/missing/corrupt guards\n")
if (!length(args)) unlink(root, recursive = TRUE)
