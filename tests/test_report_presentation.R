#!/usr/bin/env Rscript
# Complete/partial/failure presentation fixtures use actual public R outputs.
# Usage: Rscript tests/test_report_presentation.R NEW_OUTPUT_DIRECTORY
args <- commandArgs(TRUE)
if (length(args) != 1L) stop('Supply one new output directory.')
source('demo/make-input.R')
source('bin/scientific_report.R')
source('report/check-reference.R')
root <- args[[1L]]
config <- readRDS(file.path(root, 'config.rds'))
lock <- readRDS(file.path(root, 'lock.rds'))
input <- file.path(root, 'input')
helper <- normalizePath('bin/scientific_report.R')
for (stage in c('parameters', 'assignment', 'qc', 'calibration', 'power', 'discovery')) {
    output <- file.path(root, stage)
    run_stage(config, input, output, stage, 271828L, identity = lock)
    input <- output
    if (stage == 'qc') {
        state <- read_bundle(input, config, lock)
        stopifnot(write_scientific_report_safely(state$object, state$manifest, config,
            file.path(root, 'report-partial'), helper))
    }
}
state <- read_bundle(input, config, lock)
object_before <- serialize(state$object, NULL); rng <- .Random.seed
complete <- file.path(root, 'report-complete')
stopifnot(write_scientific_report_safely(state$object, state$manifest, config, complete, helper),
    identical(object_before, serialize(state$object, NULL)), identical(rng, .Random.seed))
x <- readRDS(file.path(complete, 'report-data.rds'))
receipts <- lapply(c('calibration','power','discovery'), function(key) {
    public <- sceptre::get_result(state$object, paste0('run_', switch(key, calibration='calibration_check', power='power_check', discovery='discovery_analysis')))
    summary <- x$analyses[[key]]$summary
    stopifnot(check_report_reference(complete, key, public), summary$returned_rows == nrow(public),
        summary$finite_p_values == sum(is.finite(public$p_value)),
        identical(summary$median_p_value, median(public$p_value[is.finite(public$p_value)])),
        x$plot_status[[key]]$status == 'completed')
    if (key == 'power') stopifnot(is.null(summary$significant), is.null(summary$nominal_rejections),
        !'significant' %in% names(public))
    if ('significant' %in% names(public)) stopifnot(x$analyses[[key]]$significant_count == sum(public$significant, na.rm = TRUE))
    list(family = key, rows = nrow(public), finite_p_values = summary$finite_p_values,
        median_p_value = summary$median_p_value, significant = summary$significant,
        table_sha256 = hash_file(file.path(complete, 'tables', paste0(key, '.rds'))))
})
stopifnot(x$qc$imported_cells == 320L, x$qc$retained_cells == 315L,
    x$qc$excluded_cells == 5L, sum(x$qc$failure_summary$working_pairs) >= 1L,
    x$scientific_settings$resampling_mechanism == 'permutations',
    x$scientific_settings$multiple_testing_method == 'BH',
    identical(x$scientific_settings$multiple_testing_alpha, .1))
html <- paste(readLines(file.path(complete, 'report.html')), collapse = '\n')
stopifnot(all(vapply(c('qc','calibration','power','discovery'), function(k) grepl(paste0('src="plots/', k, '.png"'), html, fixed = TRUE), logical(1))),
    grepl('Requested versus resolved settings', html, fixed = TRUE),
    grepl('does not add a hit rate', html, fixed = TRUE),
    grepl('Recorded failure reasons', html, fixed = TRUE))
failure <- file.path(root, 'report-failure')
stopifnot(!write_scientific_report_safely(state$object, state$manifest, config, failure, helper,
    renderer = function(...) stop('Synthetic visual fixture: renderer deliberately failed.')),
    file.exists(file.path(failure, 'report.html')),
    grepl('PRESENTATION UNAVAILABLE', paste(readLines(file.path(failure, 'report.html')), collapse = ''), fixed = TRUE),
    identical(object_before, serialize(state$object, NULL)), identical(rng, .Random.seed))
saveRDS(list(kind = 'sceptre-scientific-report-presentation-test', source = 'demo/make-input.R synthetic fixture',
    seed = 271828L, package = lock, renderer_sha256 = hash_file(helper), values = receipts,
    imported_cells = x$qc$imported_cells, retained_cells = x$qc$retained_cells,
    qc = x$qc$families, status = 'passed'), file.path(root, 'report-value-checks.rds'))
cat('PASS rich scientific report: real complete/partial/failure fixtures, exact public rows/CSV/RDS, summary counts/p-values/correction semantics, figures, failed QC, RNG/object immutability\n')
