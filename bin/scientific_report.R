# Pipeline-owned reporting: all scientific values come from saved public results.
# Rendering this value bundle never invokes a SCEPTRE analysis.
report_escape <- function(x) {
    x <- gsub('&', '&amp;', as.character(x), fixed = TRUE)
    x <- gsub('<', '&lt;', x, fixed = TRUE)
    x <- gsub('>', '&gt;', x, fixed = TRUE)
    gsub('"', '&quot;', x, fixed = TRUE)
}
# Schema2 freezes only bounded previews; complete scientific values/provenance
# remain in complete CSV/native exports and original config/manifest files.
report_preview <- function(x, depth = 0L, budget = NULL) {
    if (is.null(budget)) { budget <- new.env(parent = emptyenv()); budget$remaining <- 512L }
    if (budget$remaining <= 0L) return('<preview entry budget exhausted; see frozen report inputs>')
    budget$remaining <- budget$remaining - 1L
    if (inherits(x, 'formula')) return(substr(paste(deparse(x, width.cutoff = 500L, nlines = 12L), collapse = ' '), 1L, 500L))
    if (is.object(x) && is.list(x) && !is.data.frame(x) && !isS4(x))
        return(paste0('<opaque ', substr(paste(utils::head(class(x), 3L), collapse = '/'), 1L, 500L), ' object omitted; see native export>'))
    if (depth >= 5L && (is.list(x) || isS4(x))) return('<nested content omitted; see frozen report inputs>')
    if (isS4(x)) return(report_preview(stats::setNames(lapply(methods::slotNames(x),
        function(name) methods::slot(x, name)), methods::slotNames(x)), depth + 1L, budget))
    if (is.data.frame(x)) {
        out <- lapply(x[seq_len(min(nrow(x), 12L)), seq_len(min(ncol(x), 12L)), drop = FALSE],
            function(value) report_preview(value, depth + 1L, budget))
        return(list(dimensions = c(rows = nrow(x), columns = ncol(x)), first_rows_and_columns = out))
    }
    if (is.list(x)) {
        count <- length(x)
        # Standard settings/manifest structures have fewer than 64 fields.
        # Show their short scalar settings first, so a large canonical family
        # cannot consume the preview budget before budgets/seed/identity appear.
        candidates <- seq_len(min(count, 64L))
        scalar <- vapply(x[candidates], function(value) is.atomic(value) &&
            is.null(dim(value)) && length(value) <= 12L, logical(1))
        nested <- candidates[!scalar]
        metadata <- if (is.null(names(x))) integer() else nested[grepl(
            '^(plan|spec|manifest|qualified_source|package|identity|analysis|assignment|qc|execution|calibration)$', names(x)[nested])]
        selected <- c(candidates[scalar], utils::head(unique(c(metadata, nested)), 12L))
        out <- lapply(x[selected], function(value) report_preview(value, depth + 1L, budget))
        if (!is.null(names(out))) names(out) <- substr(names(out), 1L, 500L)
        if (count > length(selected)) out[['... omitted entries']] <- count - length(selected)
        return(out)
    }
    # Drop large attributes and matrix payloads before printing. Only previews
    # are reduced; no altered value is written back into the frozen bundle.
    if (is.atomic(x)) {
        count <- length(x)
        out <- as.vector(x[seq_len(min(length(x), 12L))])
        if (is.character(out)) out <- ifelse(nchar(out) > 500L,
            paste0(substr(out, 1L, 500L), ' ... [text truncated]'), out)
        if (count > 12L || !is.null(dim(x))) return(list(length = count,
            dimensions = dim(x), first_values = out))
        return(out)
    }
    if (is.null(x)) return(NULL)
    '<value omitted; see frozen report inputs>'
}
report_text <- function(x) {
    text <- paste(capture.output(dput(report_preview(x))), collapse = '\n')
    if (nchar(text) > 20000L) paste0(substr(text, 1L, 20000L), '\n... [preview text truncated; see frozen report inputs]') else text
}
report_scalar_table <- function(x, max_rows = NULL) {
    if (!is.data.frame(x)) return(data.frame())
    if (!is.null(max_rows)) x <- x[seq_len(min(nrow(x), max_rows)), , drop = FALSE]
    x <- as.data.frame(x)
    keep <- vapply(x, function(y) is.atomic(y) && is.null(dim(y)), logical(1))
    as.data.frame(x[, names(x)[keep], drop = FALSE])
}
scientific_report_html <- function(data, output, fragment = FALSE) {
    esc <- report_escape
    value <- function(x, fallback = 'Not available') if (is.null(x) || !length(x)) fallback else x
    count_text <- function(x) if (!length(x) || is.na(x[[1L]])) '\u2014' else format(x[[1L]], big.mark = ',', scientific = FALSE, trim = TRUE)
    number_text <- function(x) if (!length(x) || is.na(x[[1L]])) '\u2014' else format(signif(x[[1L]], 4L), scientific = abs(x[[1L]]) < 0.001 && x[[1L]] != 0, trim = TRUE)
    percent_text <- function(n, d) if (!length(d) || is.na(d) || d <= 0) '\u2014' else paste0(format(round(100 * n / d, 1), trim = TRUE), '%')
    table_html <- function(x, total_rows = NULL, searchable = TRUE) {
        total <- if (!is.null(total_rows)) total_rows else if (is.data.frame(x)) nrow(x) else 0L
        omitted <- if (is.data.frame(x)) setdiff(names(x), names(report_scalar_table(x, 0L))) else character()
        x <- report_scalar_table(x, 100L)
        if (!nrow(x)) return(if (total > 0L) paste0('<p class="empty">No rows included in this preview; ', count_text(total), ' complete saved rows remain available in the export.</p>') else '<p class="empty">No rows available.</p>')
        rows <- vapply(seq_len(nrow(x)), function(i) paste0('<tr>', paste(vapply(names(x), function(name) {
            raw <- x[[name]][[i]]
            shown <- if (is.numeric(raw) && is.finite(raw)) number_text(raw) else as.character(raw)
            if (is.na(raw)) shown <- 'NA'
            shown <- substr(shown, 1L, 500L)
            if (name == 'significant' && !is.na(raw)) shown <- paste0('<span class="badge ', if (isTRUE(raw)) 'positive' else 'neutral', '">', if (isTRUE(raw)) 'Yes' else 'No', '</span>') else shown <- esc(shown)
            paste0('<td title="', esc(substr(as.character(raw), 1L, 500L)), '">', shown, '</td>')
        }, character(1)), collapse = ''), '</tr>'), character(1))
        paste0('<div class="data-table">', if (searchable) '<label class="table-search">Filter displayed rows <input type="search" placeholder="Response, target, value\u2026" oninput="filterPreview(this)"></label>',
            '<p class="preview">', if (total > nrow(x)) paste0('Showing the first ', nrow(x), ' of ', count_text(total), ' rows in saved order. Preview truncated. Complete scalar columns are retained in the CSV downloads, and complete native values in the linked RDS exports.') else paste0('Showing all ', count_text(total), ' rows.'),
            '</p>', if (length(omitted)) paste0('<p class="preview">Non-scalar columns omitted from this HTML table and CSV: ', esc(paste(omitted, collapse = ', ')), '. Complete values are retained in the linked native result RDS files.</p>'),
            '<div class="table-wrap" tabindex="0" role="region" aria-label="Scrollable scientific table"><table><thead><tr>', paste0('<th scope="col">', esc(names(x)), '</th>', collapse = ''), '</tr></thead><tbody>', paste(rows, collapse = ''), '</tbody></table></div></div>')
    }
    code <- function(x) paste0('<p class="preview">Bounded metadata preview; complete settings and provenance are retained in the downloaded native files. Up to 64 short scalar settings and 12 other entries, 5 nested levels, 512 visited entries and 20,000 displayed characters.</p><pre>', esc(report_text(x)), '</pre>')
    card <- function(label, amount, detail = '', tone = '') paste0('<div class="metric ', tone, '"><span>', esc(label), '</span><strong>', esc(amount), '</strong><small>', esc(detail), '</small></div>')
    pill <- function(status) paste0('<span class="badge ', if (identical(status, 'completed')) 'positive' else if (identical(status, 'failed')) 'negative' else 'neutral', '">', esc(value(status, 'omitted')), '</span>')
    section_head <- function(kicker, title, description = '', status = NULL) paste0('<div class="section-heading"><div><p class="eyebrow">', kicker, '</p><h2>', title, '</h2></div>', if (!is.null(status)) pill(status), '</div><p class="section-intro">', description, '</p>')
    captions <- c(covariates = 'Imported cell covariates and saved QC thresholds. The package uses original cells for these distributions.',
        grna_counts = 'Guide-count distributions from the public R plotting function. Displayed guides are a package-selected sample, not the full library.',
        assignment = 'Guide-to-cell assignment diagnostics from the public R package. Memberships can overlap in high-MOI analyses.',
        qc = 'Cell exclusions and working-pair eligibility from the saved package QC state. Exclusion categories can overlap.',
        calibration = 'Public R calibration diagnostic for the sampled negative-control family. A small control family cannot establish calibration for every discovery.',
        power = 'Public R positive-control diagnostic. This is observed positive-control sensitivity, not prospective power.',
        discovery = 'Public R discovery diagnostic. Significance is copied from complete-family package correction; no p-values are recomputed here.')
    figure <- function(stage) {
        matching <- data$plots[basename(data$plots) == paste0(stage, '.png')]
        status <- data$plot_status[[stage]]
        if (!length(matching)) return(if (identical(status$status, 'failed')) paste0('<div class="notice caution"><strong>Figure unavailable.</strong> ', esc(status$reason), ' Scientific tables and the certified object remain available.</div>') else '')
        path <- paste0('plots/', basename(matching[[1L]]))
        paste0('<figure class="scientific-figure"><div class="figure-scroll" tabindex="0" role="region" aria-label="Scrollable ', esc(stage), ' scientific figure"><a href="', esc(path), '" aria-label="Open full-size ', esc(stage), ' figure"><img src="', esc(path), '" loading="lazy" width="1080" height="840" alt="', esc(captions[[stage]]), '"></a></div><figcaption><span>', esc(captions[[stage]]), '<span class="mobile-hint">Swipe the figure horizontally, or open the full-size image.</span></span><a href="', esc(path), '">Open full size \u2197</a></figcaption></figure>')
    }
    bars <- function(labels, counts, denominator, class = '') {
        if (!length(counts)) return('<p class="empty">No saved counts available.</p>')
        maximum <- max(c(counts, denominator, 1), na.rm = TRUE)
        paste0('<div class="bar-list ', class, '">', paste(vapply(seq_along(counts), function(i) paste0('<div class="bar-row"><div><span>', esc(labels[[i]]), '</span><strong>', count_text(counts[[i]]), '</strong></div><div class="bar-track"><span style="width:', if (is.na(counts[[i]])) 0 else round(100 * counts[[i]] / maximum, 2), '%"></span></div></div>'), character(1)), collapse = ''), '</div>')
    }
    manifest <- data$provenance$manifest
    analyses <- data$analyses
    status <- function(key) value(analyses[[key]]$status, 'omitted')
    complete <- sum(vapply(c('calibration','power','discovery'), function(key) identical(status(key), 'completed'), logical(1)))
    discovery <- analyses$discovery
    summary <- function(key) value(analyses[[key]]$summary, list())
    discovery_summary <- summary('discovery')
    significant <- value(discovery$significant_count, NA_integer_)
    family_total <- value(discovery$total_rows, if (is.data.frame(discovery$table)) nrow(discovery$table) else NA_integer_)
    retention <- percent_text(data$qc$retained_cells, data$qc$imported_cells)
    completed_stages <- paste(intersect(c('parameters','assignment','qc','calibration','power','discovery'), value(manifest$completed, data$qc$stages)), collapse = ' \u2192 ')
    stages <- paste(vapply(c('calibration','power','discovery'), function(key) paste0('<a class="stage-tile" href="#', key, '"><span>', c(calibration='Calibration',power='Positive controls',discovery='Discovery')[[key]], '</span>', pill(status(key)), '</a>'), character(1)), collapse = '')
    overview <- paste0('<section id="overview">', section_head('ANALYSIS OVERVIEW', 'A screen, from cells to associations', 'A scientific view of saved SCEPTRE results. Every inferential value comes from the completed R package analysis.'),
        '<div class="metrics">', card('Cells retained', count_text(data$qc$retained_cells), paste0(retention, ' of ', count_text(data$qc$imported_cells), ' imported cells')),
        card('Discovery results', if (identical(status('discovery'), 'completed')) count_text(family_total) else '\u2014', if (identical(status('discovery'), 'completed')) 'Returned target\u2013response rows' else 'Discovery was not selected'),
        card('Significant discoveries', if (identical(status('discovery'), 'completed')) count_text(significant) else '\u2014', if (identical(status('discovery'), 'completed')) 'Package complete-family correction' else 'No discovery significance call', 'accent'),
        card('Analysis stages', paste0(complete, ' / 3'), 'Completed optional scientific families'), '</div><div class="stage-grid">', stages, '</div>',
        '<div class="notice"><strong>Read this as scientific evidence.</strong> Calibration is optional and is not a prerequisite for discovery. Associations do not establish biological mechanisms. This report is distinct from the Nextflow execution report and from runtime or memory benchmarks.</div>',
        '<p class="preview">Saved stage history: ', esc(value(completed_stages, 'Not available')), '. Report generated ', esc(data$generated_utc), '.</p></section>')
    metrics <- data$qc$metrics
    metric_labels <- c(n_cells_rm_n_response_umis = 'Response UMI counts', n_cells_rm_n_nonzero_responses = 'Nonzero response counts',
        n_cells_rm_p_mito = 'Mitochondrial fraction', n_cells_rm_zero_twoplus_grnas = 'Zero or multiple guides', n_cells_rm_additional = 'User-specified exclusion', n_cells_rm_total = 'Any exclusion')
    # The package records six cell-removal counts in this fixed documented order.
    cell_labels <- c('Response UMI counts', 'Nonzero responses', 'Mitochondrial fraction', 'Zero or multiple guides', 'User-specified exclusion', 'Any exclusion')
    if (length(metrics) != 6L) cell_labels <- if (length(names(metrics))) names(metrics) else paste('Saved QC category', seq_along(metrics))
    assignments <- data$qc$assignments
    membership <- if (is.data.frame(assignments) && all(c('grna_group','cells') %in% names(assignments)))
        bars(as.character(utils::head(assignments$grna_group, 12L)), utils::head(assignments$cells, 12L), value(data$qc$imported_cells, 1L)) else '<p class="empty">Assignment counts are unavailable for this stage.</p>'
    pair_details <- paste(vapply(c('discovery','power'), function(key) {
        tab <- data$qc$pair_qc[[key]]
        total <- if (is.data.frame(data$qc$families) && all(c('family','working_pairs') %in% names(data$qc$families))) data$qc$families$working_pairs[data$qc$families$family == key] else NULL
        paste0('<details><summary>', if (key == 'power') 'Positive-control' else 'Discovery', ' working-pair QC and failure reasons</summary>', table_html(tab, total), '<p><a href="tables/qc_', key, '.csv">Complete pair-QC CSV</a> \u00b7 <a href="tables/qc_', key, '.rds">Native table RDS</a></p></details>')
    }, character(1)), collapse = '')
    qc <- paste0('<section id="qc">', section_head('PREPARATION & ELIGIBILITY', 'Assignment and quality control', 'Follow retained cells, guide memberships and the working hypotheses that passed the package\u2019s saved QC rules.'),
        '<div class="split"><div class="panel"><h3>Cell exclusions</h3><p class="preview">Saved counts; reasons can overlap and need not sum to the total.</p>', bars(cell_labels, metrics, value(data$qc$imported_cells, 1L), 'exclusions'), '</div>',
        '<div class="panel"><h3>Guide-group memberships</h3><p class="preview">First 12 groups before cell QC, in saved order. High-MOI memberships are not disjoint.</p>', membership, '<p><a href="tables/assignment_counts.csv">Download all membership counts</a></p></div></div>',
        figure('qc'), '<h3>Complete-family eligibility</h3>', table_html(data$qc$families, searchable = FALSE),
        if (is.data.frame(data$qc$failure_summary) && nrow(data$qc$failure_summary)) paste0('<h4>Recorded failure reasons</h4>', table_html(data$qc$failure_summary, searchable = FALSE)),
        '<p class="preview">These are guide-group working rows. Guide expansion can change row counts relative to the original requested target\u2013response family. Failed rows remain in the complete QC downloads; the native object preserves requested pairs. No filtering is recomputed by the renderer.</p>', pair_details,
        '<details class="figure-details"><summary>Guide assignment diagnostics</summary>', figure('assignment'), '</details>',
        '<details class="figure-details"><summary>Imported covariates and guide-count distributions</summary>', figure('covariates'), figure('grna_counts'), '</details></section>')
    result_section <- function(key, title, description) {
        result <- analyses[[key]]
        if (!identical(result$status, 'completed')) return(paste0('<section id="', key, '">', section_head('SCIENTIFIC FAMILY', title, description, value(result$status, 'omitted')),
            '<div class="notice muted"><strong>', if (identical(result$status, 'failed')) 'Analysis unavailable' else 'Stage not selected', '.</strong> ', esc(value(result$reason, 'This family has no saved completed result.')), ' No p-values, effect estimates or significance calls are inferred for this family.</div></section>'))
        total <- value(result$total_rows, if (is.data.frame(result$table)) nrow(result$table) else 0L)
        s <- summary(key)
        n_sig <- value(result$significant_count, if ('significant' %in% names(result$table)) sum(result$table$significant, na.rm = TRUE) else NA_integer_)
        download <- value(result$download, paste0('tables/', key, '.csv'))
        alpha <- value(s$alpha, value(data$scientific_settings$multiple_testing_alpha, NA_real_))
        metrics <- if (key == 'power') paste0(card('Returned controls', count_text(total), 'Supplied positive-control pairs'),
            card('Finite p-values', count_text(s$finite_p_values), 'Public positive-control result values'),
            card('Median raw p-value', number_text(s$median_p_value), 'Descriptive; no hit-rate inference'),
            card('Missing p-values', count_text(s$missing_p_values), 'Failed or unavailable rows remain visible')) else if (key == 'calibration') paste0(
            card('Negative-control rows', count_text(total), 'Actual sampled control family'),
            card('Nominal rejections', count_text(s$nominal_rejections), paste0('Raw p < ', number_text(alpha))),
            card('Corrected rejections', count_text(n_sig), 'Package family correction'),
            card('Median raw p-value', number_text(s$median_p_value), 'Descriptive; not a calibration guarantee')) else paste0(
            card('Returned associations', count_text(total), 'Complete saved family after guide integration'),
            card('Significant', count_text(n_sig), paste0(value(data$scientific_settings$multiple_testing_method, 'Package correction'), ', alpha ', number_text(alpha)), 'accent'),
            card('Finite p-values', count_text(s$finite_p_values), 'Rows eligible for this descriptive summary'),
            card('Missing p-values', count_text(s$missing_p_values), 'Consult pair-QC and native result diagnostics'))
        budget <- result$provenance$plan
        budgets <- if (is.list(budget) && length(intersect(c('B1','B2','B3'), names(budget)))) paste0('<p class="method-line"><strong>Saved resampling budgets:</strong> ', paste(vapply(intersect(c('B1','B2','B3'), names(budget)), function(k) paste0(k, ' = ', count_text(budget[[k]])), character(1)), collapse = ' \u00b7 '), '. Package plan for this family; not every pair reaches each resampling stage.</p>') else ''
        paste0('<section id="', key, '">', section_head('SCIENTIFIC FAMILY', title, description, 'completed'), '<div class="metrics">', metrics, '</div>',
            '<p class="result-count"><strong>', count_text(total), ' returned rows</strong>', if (!is.na(n_sig)) paste0('; ', count_text(n_sig), ' marked significant by SCEPTRE in the complete family.') else '.',
            if (!total) ' Completed with no returned rows; this is not evidence of no effects.' else '', '</p>', budgets,
            if (key == 'power') '<div class="notice">Observed positive-control sensitivity depends on the supplied effects, sample and QC. It is not prospective power for untested associations. This view summarizes actual p-value and effect columns; it does not add a hit rate, significance field or across-pair correction absent from the R power output.</div>',
            figure(key),
            if (key == 'discovery' && is.data.frame(result$top_associations) && nrow(result$top_associations)) paste0('<h3>Smallest saved p-values</h3><p class="preview">Up to 12 finite-p rows, sorted by raw p-value for inspection. This view does not select or correct a new family. Fold change is a ratio; log2 fold change, when present, is a different scale.</p>', table_html(result$top_associations, searchable = FALSE)),
            if (value(result$omitted_column_count, 0L) > 0L) paste0('<p class="preview">', result$omitted_column_count, ' non-scalar columns are omitted from this bounded HTML view and scalar CSV; complete native values remain in the RDS result.</p>'),
            '<details', if (total <= 12L) ' open' else '', '><summary>Saved result table</summary>', table_html(result$table, total), '</details>',
            '<div class="download-row"><a class="button" href="', esc(download), '">Complete result CSV \u2193</a>', if (!is.null(result$native_result)) paste0('<a class="button secondary" href="', esc(result$native_result), '">Native result RDS \u2193</a>'), '</div>',
            '<details><summary>Frozen family settings and realized budgets</summary>', code(result$provenance), '</details></section>')
    }
    settings <- paste0('<section id="settings">', section_head('SCIENTIFIC CONTRACT', 'Requested versus resolved settings', 'Read the choices that actually governed the saved analysis. Package defaults and MOI-dependent resolution are explicit.'),
        table_html(data$settings_table, searchable = FALSE), '<p class="preview">Guide integration and complete-family multiple-testing correction are separate steps. Calibration, power and discovery use the saved R package semantics; this report adds no second statistical engine.</p>',
        '<details><summary>Full requested configuration</summary>', code(data$requested), '</details><details><summary>Full resolved package specification</summary>', code(data$resolved), '</details></section>')
    warning_list <- if (length(data$warnings)) paste0('<div class="warning-list">', paste(vapply(utils::head(data$warnings, 100L), function(w) paste0('<div class="warning-item"><div>', pill('warning'), '<strong>', esc(value(w$stage, 'Unspecified stage')), '</strong><span>', esc(value(w$source, 'reference stage')), if (!is.null(w$unit_id)) paste0(' \u00b7 ', esc(w$unit_id)), '</span></div><p>', esc(w$message), '</p></div>'), character(1)), collapse = ''), '</div>') else '<div class="notice success">No warnings were captured within this run\u2019s recorded scope. This does not establish that upstream imports emitted none.</div>'
    plot_failures <- Filter(function(x) identical(x$status, 'failed'), data$plot_status)
    warnings <- paste0('<section id="warnings">', section_head('CONDITIONS & AVAILABILITY', 'Warnings and diagnostic availability', 'Conditions remain visible alongside the scientific output; a missing figure is never substituted with invented evidence.'),
        '<p class="preview">Capture scope: reference stages and current distributed prepare/worker/collector conditions are recorded with stage, source and worker ID where applicable. Plot warnings are included. Imports before this workflow and historical artifacts can have incomplete capture.</p>', warning_list,
        if (value(data$warning_total, length(data$warnings)) > 100L) '<p class="preview">First 100 captured conditions shown. Complete conditions are in the structured download.</p>',
        if (length(plot_failures)) paste0('<div class="notice caution">', length(plot_failures), ' figure(s) could not be produced. See the relevant scientific section and full figure-status download. Certified tables remain available.</div>'),
        '<p><a href="warnings.json">Complete structured warnings (JSON)</a> \u00b7 <a href="warnings.rds">Warnings (RDS)</a> \u00b7 <a href="plot-status.json">Per-stage figure status</a></p></section>')
    package <- manifest$package
    provenance <- paste0('<section id="downloads">', section_head('REPRODUCIBILITY & DOWNLOADS', 'Take the evidence with you', 'Native scientific values, full tables and exact source identities remain available beyond this bounded presentation.'),
        '<dl class="identity-grid"><div><dt>Workflow seed</dt><dd>', esc(value(manifest$seed, 'Not recorded')), '</dd></div><div><dt>R package version</dt><dd>', esc(value(package$version, 'See manifest')), '</dd></div><div><dt>Execution mode</dt><dd>', esc(value(manifest$execution$mode, 'Reference / saved state')), '</dd></div><div><dt>Count backend</dt><dd>', esc(value(manifest$backend, 'See native object')), '</dd></div></dl>',
        '<div class="download-grid"><a href="sceptre_object.rds"><strong>Native SCEPTRE object</strong><span>Full scientific state \u00b7 RDS</span></a><a href="portable-manifest.rds"><strong>Portable object manifest</strong><span>Object and backing SHA256 identities</span></a><a href="manifest.rds"><strong>Pipeline provenance</strong><span>Source, runtime, parents and RNG</span></a><a href="requested-config.rds"><strong>Original configuration</strong><span>Complete requested scientific settings</span></a><a href="report-data.rds"><strong>Frozen report view</strong><span>Bounded previews and exact summaries</span></a><a href="reopen_export.R"><strong>Portable reopen helper</strong><span>Uses the public validated R reader</span></a></div>',
        '<div class="notice"><strong>HDF5 portability.</strong> Copy this complete report directory, including <code>backing/</code>, <code>sceptre_object.rds</code>, <code>portable-manifest.rds</code> and <code>reopen_export.R</code>. Downloading the RDS alone is insufficient for a backed screen.</div>',
        '<pre class="usage">source("reopen_export.R")\nobject &lt;- reopen_sceptre_export(".")</pre>',
        '<details><summary>Exact manifest and scientific provenance</summary>', code(data$provenance), '</details>',
        '<p class="preview"><a href="render.R">Editable base-R renderer</a> \u00b7 <a href="rerender.R">Rerender entry point</a> \u00b7 <a href="report.qmd">Quarto source</a>. Rendering these frozen values reruns no scientific analysis. The report does not establish arbitrary-scale, cluster or performance qualification.</p></section>')
    navigation <- '<nav aria-label="Scientific report sections"><a href="#overview">Overview</a><a href="#qc">Assignment &amp; QC</a><a href="#calibration">Calibration</a><a href="#power">Positive controls</a><a href="#discovery">Discovery</a><a href="#settings">Scientific settings</a><a href="#warnings">Warnings</a><a href="#downloads">Provenance &amp; downloads</a></nav>'
    body <- paste0('<header class="report-header"><div class="brand">SCEPTRE <span>SCIENTIFIC REPORT</span></div><div class="header-copy"><p class="eyebrow">FROM SCREEN TO SCIENTIFIC EVIDENCE</p><h1>', esc(value(data$title, 'Screen analysis')), '</h1><p>Quality, controls, associations and the exact choices behind them.</p></div><div class="header-meta"><span>Saved scientific output</span><strong>', complete, ' scientific families completed</strong></div></header><div class="report-layout">', navigation, '<main>', overview, qc,
        result_section('calibration', 'Calibration check', 'Inspect the actual sampled negative-control family and its public R calibration diagnostics. This family is optional.'),
        result_section('power', 'Positive-control sensitivity', 'Review effects and p-values for the supplied positive-control associations, including missing or failed-QC rows.'),
        result_section('discovery', 'Discovery associations', 'Explore effect estimates and package significance calls after complete-family guide integration and correction.'), settings, warnings, provenance,
        '</main></div><footer>Generated from saved public SCEPTRE outputs \u00b7 Scientific analysis is not rerun by this report \u00b7 ', esc(data$generated_utc), '</footer>')
    style <- '<style>:root{font-family:Inter,ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;color:#203631;background:#edf1ed;font-synthesis:none;font-size:15px;line-height:1.55;--green:#155e46;--ink:#18382e;--muted:#60756b;--border:#d8e1d9}*{box-sizing:border-box}html{scroll-behavior:auto;scroll-padding-top:0}body{margin:0}a{color:#135d49;text-underline-offset:3px}a:hover{color:#092f24}h1,h2,h3,h4,p{margin-top:0}h1{font-size:clamp(32px,4vw,48px);letter-spacing:-1.7px;line-height:1.12;max-width:820px;margin-bottom:14px}h2{font-size:28px;line-height:1.2;letter-spacing:-.8px;margin-bottom:0}h3{font-size:19px;letter-spacing:-.3px;margin:22px 0 12px}h4{font-size:16px;margin-bottom:10px}p{margin-bottom:16px;overflow-wrap:anywhere}.report-header{background:#113f31;color:#f5f7f0;padding:26px max(32px,calc((100vw - 1350px)/2));display:grid;grid-template-columns:1fr auto;column-gap:30px;min-height:270px}.brand{font-size:21px;font-weight:800;letter-spacing:3px;grid-column:1/-1;display:flex;align-items:center;gap:20px}.brand span{font-size:10px;letter-spacing:2px;font-weight:600;border-left:1px solid #668377;padding-left:20px;color:#ccdfcf}.header-copy{padding-top:34px}.header-copy .eyebrow{color:#b5d5b4}.header-copy>p:last-child{color:#c5d6cb;max-width:650px;margin-bottom:20px}.header-meta{align-self:end;text-align:right;font-size:12px;color:#c5d6cb;padding-bottom:22px}.header-meta span,.header-meta strong{display:block}.header-meta strong{color:#f0f7ee;font-weight:500;margin-top:5px}.eyebrow{font-size:10px;letter-spacing:1.6px;font-weight:750;color:#46715c;margin-bottom:8px}.report-layout{max-width:1400px;margin:auto;display:grid;grid-template-columns:205px minmax(0,1fr);gap:28px;padding:28px 28px 36px}nav{position:sticky;top:24px;align-self:start;display:flex;flex-direction:column;gap:5px;padding-top:9px}nav a{font-size:13px;text-decoration:none;padding:10px 12px;border-radius:5px;color:#526b5d;border-left:3px solid transparent}nav a:hover,nav a:focus,nav a[aria-current="location"]{background:#dce8dc;color:#164e36;border-left-color:#33784d}nav a:first-child{font-weight:700}main{min-width:0}section{background:#fff;border:1px solid var(--border);border-radius:9px;padding:28px;margin-bottom:22px;box-shadow:0 2px 4px #18382e03;scroll-margin-top:22px}.section-heading{display:flex;align-items:center;justify-content:space-between;gap:18px;margin-bottom:16px}.section-intro{color:#5b7064;font-size:14px;max-width:850px;margin-bottom:23px}.metrics{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:12px;margin:20px 0}.metric{background:#f4f7f2;border:1px solid #e1e8df;border-radius:6px;padding:17px 16px;min-width:0}.metric>span{display:block;font-size:11px;font-weight:650;color:#5f7566}.metric strong{display:block;font-size:32px;line-height:1.15;letter-spacing:-1px;color:#1d4531;margin:10px 0}.metric small{display:block;font-size:10px;line-height:1.5;color:#708075}.metric.accent{background:#e1edde;border-color:#c7d9c2}.stage-grid{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:10px;margin:20px 0}.stage-tile{display:flex;align-items:center;justify-content:space-between;gap:8px;text-decoration:none;border:1px solid var(--border);border-radius:5px;padding:12px;font-size:12px;font-weight:650}.badge{display:inline-block;font-size:10px;line-height:1.5;font-weight:700;padding:3px 8px;border-radius:30px;white-space:nowrap;text-transform:capitalize}.badge.positive{background:#dcebdd;color:#276337}.badge.neutral{background:#eef0ed;color:#657168}.badge.negative{background:#f7e7de;color:#954d2a}.notice{padding:15px 17px;background:#f0f5ee;border-left:3px solid #90af88;border-radius:3px;font-size:12px;line-height:1.65;margin:18px 0;color:#50694f}.notice strong{color:#294e32}.notice.caution{background:#fff4e8;border-left-color:#d7aa65;color:#7d5e31}.notice.success{background:#edf5eb}.notice.muted{background:#f6f7f4;border-left-color:#c0c9bb}.preview,.empty{font-size:11px;line-height:1.6;color:#738077;margin:10px 0}.empty{font-size:13px;padding:14px 0}.split{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:18px}.panel{border:1px solid #e0e7de;padding:18px;border-radius:6px;min-width:0}.panel h3{margin-top:0}.bar-row{margin:13px 0}.bar-row>div:first-child{display:flex;justify-content:space-between;gap:12px;font-size:11px;color:#647565;margin-bottom:5px}.bar-row strong{color:#294b32;font-size:11px;font-variant-numeric:tabular-nums}.bar-track{height:6px;border-radius:4px;background:#edf1e9;overflow:hidden}.bar-track>span{height:100%;background:#638e65;display:block;border-radius:4px}.exclusions .bar-track>span{background:#c6a16c}.scientific-figure{margin:24px 0;border:1px solid #e5eae1;border-radius:6px;background:white;overflow:hidden}.scientific-figure img{display:block;width:100%;height:auto;max-width:100%}.figure-scroll>a{display:block}.figure-scroll{overflow-x:auto}.mobile-hint{display:none}.scientific-figure figcaption{padding:12px 15px;border-top:1px solid #edf0ea;display:flex;justify-content:space-between;gap:16px;font-size:11px;color:#73806f;background:#fafbf8}.scientific-figure figcaption>a{white-space:nowrap}.data-table{margin:15px 0}.table-search{display:flex;align-items:center;justify-content:space-between;gap:15px;font-size:11px;color:#70816e;flex-wrap:wrap}input[type=search]{border:1px solid #d6e0d0;background:#fafcf8;border-radius:5px;padding:8px 10px;width:230px;max-width:100%;font:inherit;color:#264b30}.table-wrap{max-height:420px;overflow:auto;border:1px solid #dce4d7;border-radius:5px;max-width:100%}table{border-collapse:collapse;width:100%;font-size:11px;font-variant-numeric:tabular-nums}th,td{padding:11px 12px;border-bottom:1px solid #e7ece3;text-align:left;white-space:nowrap}th{position:sticky;top:0;background:#edf3e8;color:#4e684d;font-size:10px;z-index:1}tr:nth-child(even){background:#fafcf8}tbody tr:last-child td{border-bottom:0}.result-count,.method-line{font-size:12px;color:#5c705b}.download-row{display:flex;flex-wrap:wrap;gap:10px;margin:18px 0}.button{display:inline-block;padding:10px 15px;border-radius:5px;background:#286545;color:white;text-decoration:none;font-size:11px;font-weight:650}.button:hover{color:white;background:#174d31}.button.secondary{background:#f0f5ec;color:#385e3c;border:1px solid #d6e2cf}details{border-top:1px solid #e5eade;padding:2px 0;margin-top:12px}summary{cursor:pointer;padding:15px 0;font-size:12px;font-weight:650;color:#385c3b}details[open]>summary{color:#1e492d}.figure-details .scientific-figure{margin-top:8px}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#f3f6ef;border:1px solid #e0e7d8;border-radius:5px;padding:17px;font:11px/1.6 ui-monospace,SFMono-Regular,Consolas,monospace;max-height:400px;overflow:auto}.usage{color:#365b3c;font-size:12px}code{font:11px ui-monospace,SFMono-Regular,monospace}.identity-grid{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:15px;margin:20px 0 25px}.identity-grid div{border-left:2px solid #ccdcbc;padding-left:12px;min-width:0}dt{font-size:10px;color:#789071}dd{margin:6px 0 0;font-size:12px;font-weight:650;overflow-wrap:anywhere;color:#345331}.download-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px}.download-grid a{display:block;text-decoration:none;padding:15px;border:1px solid #dbe6d2;border-radius:5px;background:#fafcf7}.download-grid strong{display:block;font-size:12px}.download-grid span{display:block;font-size:10px;color:#7a8a73;margin-top:5px}.warning-item{padding:14px 15px;background:#fff9ee;border:1px solid #eee2c9;border-radius:5px;margin:10px 0}.warning-item>div{display:flex;align-items:center;gap:10px;flex-wrap:wrap;font-size:11px}.warning-item>div>span:last-child{color:#8d836b}.warning-item p{font-size:12px;line-height:1.6;margin:10px 0 0;color:#756548}footer{font-size:10px;text-align:center;color:#83907e;padding:0 25px 30px}*:focus-visible{outline:2px solid #50945e;outline-offset:3px}@media(max-width:1100px){.report-layout{grid-template-columns:165px minmax(0,1fr);gap:18px;padding:20px}nav a{padding:9px 7px;font-size:12px}section{padding:23px}.metric{padding:14px 12px}.metric strong{font-size:28px}.stage-tile{flex-direction:column;align-items:flex-start}.header-meta{display:none}.report-header{grid-template-columns:1fr}}@media(max-width:760px){html{scroll-padding-top:0}.report-header{padding:22px 20px;min-height:245px}.brand{font-size:19px;gap:12px}.brand span{font-size:8px;padding-left:12px;letter-spacing:1px}.header-copy{padding-top:30px}h1{letter-spacing:-1px;font-size:34px}.report-layout{display:block;padding:0 12px 20px}nav{position:sticky;top:0;z-index:5;margin:0 -12px 16px;padding:10px 12px;display:flex;flex-direction:row;gap:6px;background:#edf1edf5;backdrop-filter:blur(9px);overflow-x:auto;white-space:nowrap;border-bottom:1px solid #d6dfd0}nav a{display:block;padding:8px 10px;flex-shrink:0;background:#f8faf5;font-size:11px;border:1px solid #dce4d6;border-radius:4px}nav a:hover{border:1px solid #9db796}section{padding:20px 16px;margin-bottom:16px;scroll-margin-top:78px}h2{font-size:25px}.section-heading{align-items:flex-start;gap:10px}.section-intro{font-size:12px}.metrics{grid-template-columns:repeat(2,minmax(0,1fr));gap:8px}.metric{padding:13px 11px}.metric strong{font-size:28px}.metric small{font-size:9px}.stage-grid{grid-template-columns:1fr;gap:6px}.stage-tile{flex-direction:row;align-items:center;padding:10px 12px}.split{grid-template-columns:1fr}.panel{padding:15px}.scientific-figure{margin:18px -7px;border-radius:3px}.figure-scroll>a{min-width:720px}.mobile-hint{display:block;margin-top:6px;color:#6d8165}.scientific-figure figcaption{padding:10px;display:block;font-size:10px}.scientific-figure figcaption a{display:block;margin-top:8px}.identity-grid{grid-template-columns:repeat(2,minmax(0,1fr));gap:16px}.download-grid{grid-template-columns:1fr}.notice{padding:13px 12px;font-size:11px}.table-search{display:block}.table-search input{display:block;width:100%;margin-top:8px}th,td{padding:10px;font-size:10px}.preview{font-size:10px}.button{padding:9px 12px}.report-header .eyebrow{font-size:9px}}@media print{nav{display:none}.report-layout{display:block;padding:0}.report-header{background:white;color:#173c28;padding:20px}.header-copy .eyebrow,.header-copy>p:last-child{color:#56734f}section{break-inside:avoid;border:0;border-bottom:1px solid #ddd}.table-wrap{max-height:none}.metrics{grid-template-columns:repeat(4,1fr)}.scientific-figure img{max-height:700px;object-fit:contain}details:not([open]){display:none}.table-search{display:none}}</style>'
    script <- '<script>function filterPreview(input){const rows=input.closest(".data-table").querySelectorAll("tbody tr");const q=input.value.toLowerCase();rows.forEach(row=>{row.hidden=!row.textContent.toLowerCase().includes(q)});}document.querySelectorAll("nav a").forEach(a=>a.addEventListener("click",()=>{document.querySelectorAll("nav a").forEach(x=>x.removeAttribute("aria-current"));a.setAttribute("aria-current","location")}));</script>'
    html <- if (fragment) paste0(style, body, script) else paste0('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>', esc(value(data$title, 'SCEPTRE scientific report')), '</title>', style, '</head><body>', body, script, '</body></html>')
    if (!is.null(output)) writeLines(html, output, useBytes = TRUE)
    invisible(html)
}
# Convert report metadata to base-R values so standalone rendering loads no package.
report_saved_value <- function(x) {
    if (inherits(x, "formula")) return(paste(deparse(x), collapse = " "))
    if (isS4(x)) return(stats::setNames(lapply(methods::slotNames(x), function(name)
        report_saved_value(methods::slot(x, name))), methods::slotNames(x)))
    if (is.data.frame(x)) return(as.data.frame(x))
    if (is.list(x)) return(lapply(x, report_saved_value))
    x
}
# Saved schema-7 QC payloads have no exported package getter in this candidate.
# Read those durable tables without invoking private functions or changing state.
report_pair_qc <- function(object) {
    tables <- list(discovery = object@preparation@discovery_pairs_with_info,
        power = object@preparation@positive_control_pairs_with_info)
    lapply(tables, function(table) {
        if (!nrow(table)) return(table)
        reasons <- lapply(seq_len(nrow(table)), function(i) {
            out <- character()
            if (is.na(table$n_nonzero_trt[[i]]) || table$n_nonzero_trt[[i]] < object@spec@n_nonzero_trt_thresh)
                out <- c(out, "treated_nonzero_below_threshold")
            if (is.na(table$n_nonzero_cntrl[[i]]) || table$n_nonzero_cntrl[[i]] < object@spec@n_nonzero_cntrl_thresh)
                out <- c(out, "control_nonzero_below_threshold")
            if (!isTRUE(table$pass_qc[[i]]) && !length(out)) out <- "package_failed_qc_other"
            paste(out, collapse = ";")
        })
        table$failure_reasons <- unlist(reasons, use.names = FALSE)
        table
    })
}
report_scientific_plots <- function(object, completed, directory, plot_functions = NULL) {
    functions <- list(covariates = sceptre::plot_covariates, grna_counts = sceptre::plot_grna_count_distributions,
        assignment = sceptre::plot_assign_grnas, qc = sceptre::plot_run_qc,
        calibration = sceptre::plot_run_calibration_check, power = sceptre::plot_run_power_check,
        discovery = sceptre::plot_run_discovery_analysis)
    if (!is.null(plot_functions)) functions <- plot_functions
    dir.create(file.path(directory, "plots"), showWarnings = FALSE)
    # Plot sampling cannot affect the certified workflow RNG or a later stage.
    kind <- RNGkind(); had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
    if (had_seed) seed <- get(".Random.seed", envir = .GlobalEnv)
    on.exit({ do.call(RNGkind, as.list(kind)); if (had_seed) assign(".Random.seed", seed, envir = .GlobalEnv)
        else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv) }, add = TRUE)
    paths <- character(); statuses <- list(); warnings <- list()
    for (stage in names(functions)) {
        required <- if (stage %in% c("covariates", "grna_counts")) "parameters" else stage
        if (!required %in% completed) { statuses[[stage]] <- list(status = "omitted", reason = "Stage was not selected."); next }
        path <- file.path(directory, "plots", paste0(stage, ".png"))
        tryCatch({
            withCallingHandlers({
                figure <- functions[[stage]](object)
                ggplot2::ggsave(path, plot = figure, width = 9, height = 7, dpi = 120)
            }, warning = function(condition) {
                warnings[[length(warnings) + 1L]] <<- list(stage = stage, source = "scientific_plot",
                    message = conditionMessage(condition), class = class(condition))
            })
            paths <- c(paths, paste0("plots/", basename(path)))
            statuses[[stage]] <- list(status = "completed", artifact = paste0("plots/", basename(path)))
        }, error = function(condition) {
            unlink(path)
            statuses[[stage]] <<- list(status = "failed", reason = conditionMessage(condition))
        })
    }
    list(paths = paths, status = statuses, warnings = warnings)
}
report_result_summary <- function(table, alpha) {
    p <- if ("p_value" %in% names(table)) table$p_value else numeric()
    finite <- is.finite(p)
    effect <- if ("fold_change" %in% names(table)) table$fold_change else numeric()
    list(returned_rows = nrow(table), finite_p_values = sum(finite),
        missing_p_values = if (length(p)) sum(!finite) else nrow(table),
        minimum_p_value = if (any(finite)) min(p[finite]) else NA_real_,
        median_p_value = if (any(finite)) stats::median(p[finite]) else NA_real_,
        nominal_rejections = if (length(alpha)) sum(p[finite] < alpha) else NA_integer_,
        alpha = alpha, finite_fold_changes = sum(is.finite(effect)),
        median_fold_change = if (any(is.finite(effect))) stats::median(effect[is.finite(effect)]) else NA_real_,
        significant = if ("significant" %in% names(table)) sum(table$significant, na.rm = TRUE) else NULL)
}
report_scientific_settings <- function(object, manifest) {
    spec <- object@spec
    saved <- list(moi = if (S4Vectors::metadata(sceptre::get_screen_experiment(object))$sceptre$low_moi) "low" else "high",
        control_group = if (isTRUE(spec@control_group_complement)) "complement" else "nt_cells",
        resampling_mechanism = if (isTRUE(spec@run_permutations)) "permutations" else "crt",
        resampling_approximation = spec@resampling_approximation,
        side = c("left", "both", "right")[spec@side_code + 2L],
        grna_integration_strategy = spec@grna_integration_strategy,
        formula_object = paste(deparse(spec@formula_object), collapse = " "),
        multiple_testing_alpha = spec@multiple_testing_alpha,
        multiple_testing_method = spec@multiple_testing_method,
        assignment = spec@grna_assignment_method)
    for (key in intersect(names(saved), names(manifest$resolved))) saved[[key]] <- manifest$resolved[[key]]
    saved
}
report_setting_rows <- function(config, resolved) {
    labels <- c(moi = "Multiplicity of infection", control_group = "Control group",
        resampling_mechanism = "Resampling mechanism", resampling_approximation = "Approximation",
        side = "Test direction", grna_integration_strategy = "Guide integration",
        formula_object = "Covariate formula", multiple_testing_alpha = "Multiple-testing alpha",
        multiple_testing_method = "Correction method", assignment = "Guide assignment")
    display <- function(x, default = "Package default") {
        if (is.null(x) || !length(x)) return(default)
        if (inherits(x, "formula")) return(paste(deparse(x), collapse = " "))
        if (length(x) == 1L && is.atomic(x)) return(as.character(x))
        paste0("See full configuration (", length(x), " values)")
    }
    requested <- vapply(names(labels), function(key) {
        if (key == "moi") return("Frozen at import")
        if (key == "assignment") return(display(config$assignment$method))
        display(config$analysis[[key]])
    }, character(1))
    data.frame(setting = unname(labels), requested = unname(requested),
        resolved = vapply(names(labels), function(key) display(resolved[[key]], "Not available"), character(1)),
        row.names = NULL, check.names = FALSE)
}
# Freeze public schema-7 results. Rendering reads these saved values only.
export_scientific_report <- function(object, manifest, config, directory, helper_path,
    renderer = scientific_report_html, source_files = list()) {
    stopifnot(identical(object@schema_version, 7L))
    dir.create(file.path(directory, "tables"), recursive = TRUE, showWarnings = FALSE)
    analyses <- c(calibration = "run_calibration_check", power = "run_power_check",
        discovery = "run_discovery_analysis")
    results <- lapply(names(analyses), function(stage) {
        if (!stage %in% manifest$completed) return(list(status = "omitted", reason = "Stage was not selected."))
        table <- sceptre::get_result(object, analyses[[stage]])
        utils::write.csv(report_scalar_table(table), file.path(directory, "tables", paste0(stage, ".csv")), row.names = FALSE)
        saveRDS(table, file.path(directory, "tables", paste0(stage, ".rds")))
        summary <- report_result_summary(table, object@spec@multiple_testing_alpha)
        # Positive controls intentionally have no across-family significance or derived hit rate.
        if (stage == "power") summary$nominal_rejections <- NULL
        finite_order <- if ("p_value" %in% names(table)) order(table$p_value, na.last = NA) else integer()
        if (length(finite_order)) finite_order <- finite_order[is.finite(table$p_value[finite_order])]
        top <- if (stage == "discovery") report_scalar_table(table[utils::head(finite_order, 12L), , drop = FALSE]) else NULL
        omitted <- setdiff(names(table), names(report_scalar_table(table, 0L)))
        list(status = "completed", total_rows = nrow(table), table = report_scalar_table(table, 100L),
            summary = summary, top_associations = top, omitted_columns = utils::head(omitted, 12L),
            omitted_column_count = length(omitted),
            native_result = paste0("tables/", stage, ".rds"),
            significant_count = if ("significant" %in% names(table)) sum(table$significant, na.rm = TRUE) else NA_integer_,
            provenance = report_preview(object@results[[sub("^run_", "", analyses[[stage]])]]$provenance))
    })
    names(results) <- names(analyses)
    imported <- ncol(sceptre::get_screen_experiment(object))
    retained <- if ("qc" %in% manifest$completed) length(object@preparation@analysis_cells) else imported
    assignments <- if ("assignment" %in% manifest$completed) sceptre::get_grna_assignments(object) else NULL
    counts <- if (!is.null(assignments)) data.frame(grna_group = rownames(assignments), cells = as.numeric(Matrix::rowSums(assignments))) else data.frame()
    data <- list(report_schema = 3L, title = "SCEPTRE scientific results",
        generated_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
        analyses = results, qc = list(imported_cells = imported, retained_cells = retained,
            excluded_cells = imported - retained, stages = intersect(manifest$completed, c("parameters", "assignment", "qc")),
            assignments = utils::head(counts, 100L), assignment_total_rows = nrow(counts),
            families = data.frame(), metrics = object@preparation@cell_removal_metrics),
        plots = character(), warnings = manifest$warnings, requested = report_preview(config),
        resolved = report_preview(object@spec), provenance = list(manifest = report_preview(manifest)))
    qc_tables <- report_pair_qc(object)
    family_rows <- lapply(names(qc_tables), function(stage) {
        table <- qc_tables[[stage]]
        utils::write.csv(report_scalar_table(table), file.path(directory, "tables", paste0("qc_", stage, ".csv")), row.names = FALSE)
        saveRDS(table, file.path(directory, "tables", paste0("qc_", stage, ".rds")))
        data.frame(family = stage, working_pairs = nrow(table),
            passing_qc = if ("pass_qc" %in% names(table)) sum(table$pass_qc, na.rm = TRUE) else 0L,
            failed_qc = if ("pass_qc" %in% names(table)) sum(!table$pass_qc, na.rm = TRUE) else 0L)
    })
    data$qc$families <- do.call(rbind, family_rows)
    reason_rows <- lapply(names(qc_tables), function(stage) {
        table <- qc_tables[[stage]]
        if (!nrow(table)) return(NULL)
        reasons <- unlist(strsplit(table$failure_reasons[nzchar(table$failure_reasons)], ";", fixed = TRUE))
        if (!length(reasons)) return(NULL)
        counts <- table(reasons)
        data.frame(family = stage, failure_reason = names(counts), working_pairs = as.integer(counts), row.names = NULL)
    })
    data$qc$failure_summary <- do.call(rbind, reason_rows)
    data$scientific_settings <- report_scientific_settings(object, manifest)
    data$settings_table <- report_setting_rows(config, data$scientific_settings)
    data$qc$pair_qc <- lapply(qc_tables, utils::head, 100L)
    utils::write.csv(counts, file.path(directory, "tables", "assignment_counts.csv"), row.names = FALSE)
    figures <- report_scientific_plots(object, manifest$completed, directory)
    data$plots <- figures$paths; data$plot_status <- figures$status
    data$warnings <- c(data$warnings, figures$warnings)
    if (!length(data$warnings)) data$warnings <- list()
    saveRDS(data$warnings, file.path(directory, "warnings.rds"))
    jsonlite::write_json(data$warnings, file.path(directory, "warnings.json"), auto_unbox = TRUE, pretty = TRUE)
    data$warning_total <- length(data$warnings)
    data$warnings <- utils::head(data$warnings, 100L)
    jsonlite::write_json(figures$status, file.path(directory, "plot-status.json"), auto_unbox = TRUE, pretty = TRUE)
    saveRDS(data, file.path(directory, "report-data.rds"))
    saveRDS(manifest, file.path(directory, "manifest.rds"))
    saveRDS(config, file.path(directory, "requested-config.rds"))
    portable_helper <- file.path(dirname(helper_path), "reopen_export.R")
    source(portable_helper, local = environment())
    write_portable_sceptre_export(object, directory)
    if (!file.copy(portable_helper, file.path(directory, "reopen_export.R"), overwrite = TRUE)) stop("Could not copy portable reopen helper.")
    file.copy(helper_path, file.path(directory, "render.R"), overwrite = TRUE)
    writeLines(c('source("render.R")', 'scientific_report_html(readRDS("report-data.rds"), "report.html")'), file.path(directory, "rerender.R"))
    writeLines(c('---', 'title: "SCEPTRE scientific results"', 'format: html', '---',
        '```{r}', 'source("render.R")', 'cat(scientific_report_html(readRDS("report-data.rds"), NULL, fragment = TRUE))', '```'), file.path(directory, "report.qmd"))
    renderer(data, file.path(directory, "report.html"))
    invisible(data)
}
report_failure_html <- function(reason, directory) {
    links <- c("sceptre_object.rds" = "Saved native scientific object", "portable-manifest.rds" = "Portable backing manifest",
        "manifest.rds" = "Scientific provenance", "tables/discovery.csv" = "Discovery results", "tables/calibration.csv" = "Calibration results",
        "tables/power.csv" = "Positive-control results", "tables/qc_discovery.csv" = "Discovery pair QC", "warnings.json" = "Structured warnings")
    links <- links[file.exists(file.path(directory, names(links)))]
    paste0('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>SCEPTRE report unavailable</title><style>*{box-sizing:border-box}body{margin:0;background:#edf1ed;color:#274536;font:15px/1.6 system-ui,sans-serif}header{background:#113f31;color:white;padding:25px 7vw;font-size:18px;letter-spacing:2px;font-weight:750}main{max-width:850px;margin:55px auto;padding:32px;background:white;border:1px solid #d7e1d4;border-radius:8px}h1{font-size:32px;line-height:1.2;letter-spacing:-1px}p{overflow-wrap:anywhere}.status{display:inline-block;color:#8b5527;background:#f8ebd8;border-radius:20px;font-size:11px;padding:4px 10px;font-weight:700}.error{padding:18px;background:#fff7ec;border-left:3px solid #ccaa70;font:12px/1.6 ui-monospace,monospace;overflow-wrap:anywhere}a{color:#24653d}li{margin:12px 0}footer{font-size:11px;color:#7f8a7a;margin-top:28px}@media(max-width:600px){main{margin:20px 12px;padding:24px 18px}h1{font-size:28px}header{padding:20px}}</style></head><body><header>SCEPTRE <small>SCIENTIFIC REPORT</small></header><main><span class="status">PRESENTATION UNAVAILABLE</span><h1>The scientific report could not be rendered.</h1><p>This presentation failure does not revoke an already certified scientific stage. No replacement p-values, effect estimates or claims are inferred.</p><p class="error">', report_escape(reason), '</p><h2>Available scientific evidence</h2><p>Files below were saved before the rendering failure. A missing file is not implied to exist.</p><ul>', paste0('<li><a href="', names(links), '">', links, '</a></li>', collapse = ''), '</ul><p>For backed screens, keep the complete directory and its backing files together. Repair the renderer and rerun the export task; scientific stages remain independently certified.</p><footer>This page reports a failed presentation. Check report-status.json and the workflow logs for the complete failure context.</footer></main></body></html>')
}
write_scientific_report_safely <- function(object, manifest, config, directory, helper_path,
    renderer = scientific_report_html) {
    dir.create(directory, recursive = TRUE, showWarnings = FALSE)
    tryCatch({
        export_scientific_report(object, manifest, config, directory, helper_path, renderer)
        jsonlite::write_json(list(status = "completed", artifact = "report.html"),
            file.path(directory, "report-status.json"), auto_unbox = TRUE, pretty = TRUE)
        invisible(TRUE)
    }, error = function(condition) {
        jsonlite::write_json(list(status = "failed", reason = conditionMessage(condition), artifact = "report.html"),
            file.path(directory, "report-status.json"), auto_unbox = TRUE, pretty = TRUE)
        try(writeLines(report_failure_html(conditionMessage(condition), directory), file.path(directory, "report.html")), silent = TRUE)
        message("Scientific report unavailable: ", conditionMessage(condition))
        invisible(FALSE)
    })
}
