# Scientific delivery and portable objects

This surface uses the selected schema-7 R package for every association,
complete-family correction and scientific figure. It does not calculate a
second statistical result in the report renderer.

The final `scientific-report/` directory contains complete scalar result CSVs,
complete native table RDS files, original requested configuration, saved
resolved settings, the pipeline/source manifest and an editable base-R HTML
renderer. The HTML previews at most 100 rows; CSV/RDS exports are complete.

## Quality control and figures

`tables/qc_discovery.csv` and `tables/qc_power.csv` retain **all saved working
pairs**, including failures, `pass_qc`, treated/control nonzero counts and
explicit threshold failure reasons. Native RDS tables are also supplied.
Guide-group expansion means working rows need not match the original requested
target–response pair count. Original requested families remain in the native
object. The selected package has no public pair-QC getter: delivery reads the
schema-7 saved PreparationRecord tables without invoking private functions or
modifying their scientific columns. Reasons annotate the stored nonzero counts
against the stored thresholds; they never filter or rerun the analysis.

Eligible public covariate, guide-count, assignment, QC, calibration, power and discovery plots are
exported separately. Plot-stage omissions and failures are explicit in
`plot-status.json`; a failed figure does not suppress independent figures,
tables or the native object. Public plot sampling restores the incoming R RNG
kind/state. Calibration remains optional and is not a discovery prerequisite.
Full assignment membership counts appear in `tables/assignment_counts.csv`.

`warnings.json`/`warnings.rds` retain captured R condition messages/classes,
stage and distributed source; worker warnings also include the work-unit ID.
Warnings from preparation, workers and collection are aggregated in stable
work-unit order, without modifying the package-certified named proposal or
its digest. Pipeline-only warning attributes are removed before the exact
proposal reaches the public collector. Earlier imports, historical bundles and
unselected stages are outside the capture scope. Empty warnings are not a
guarantee that external input preparation emitted none.

## Portable reopening

Copy the **complete** final report directory, including:

- `sceptre_object.rds` and `portable-manifest.rds`;
- `backing/` (content-addressed immutable `.h5` files) for HDF5-backed screens;
- `reopen_export.R`.

From R:

```r
source("path/to/scientific-report/reopen_export.R")
object <- reopen_sceptre_export("path/to/scientific-report")
```

The manifest binds the saved object and each required backing file by SHA256.
Reopening relocates standard HDF5 descriptors and calls the package's public
`read_sceptre_object()` with replacement matrices. Package import anchors,
view/label/content validation and object validity remain authoritative; the
helper does not rewrite identities or bypass validation. Memory inputs need no
backing directory. The original input/work paths may be physically absent.
Downloading only an HDF5-backed object's RDS is insufficient.

A certified scientific stage is published before optional report generation.
`report-status.json` records renderer failure; original certified object and
manifest remain unchanged. Existing export-task behavior still signals report
failure to Nextflow so it is visible and retryable; no scientific task must be
rerun to repair an HTML renderer.

## Qualification scope

`Rscript tests/test_delivery.R` exercises saved failed-QC rows/reasons, public
QC figures, omitted analyses, exact direct-R versus distributed discovery,
structured worker-warning transport, RNG preservation, figure/render failures,
certified-artifact immutability, relocation with original HDF5 paths absent,
missing/corrupt backing rejection and package validation after transport hashes
are rewritten. These are small bounded fixtures, not a memory, full-screen,
HPC or arbitrary-scale qualification. The source archive/runtime identity is
retained in the existing pipeline manifest.

## Scientific report presentation

The HTML organizes the saved scientific evidence into a navigable overview,
cell/guide/QC diagnostics, optional calibration and positive-control families,
discovery effects/significance, scientific settings, warnings and portable
provenance/downloads. Public R figures appear directly inside their scientific
sections. Additional assignment/covariate/guide-count diagnostics are available
in expandable sections. Mobile figures and wide tables scroll inside their own
regions; their original full-size assets remain linked.

Overview and family summaries use complete saved tables, before deterministic
preview truncation: returned rows, finite/missing p-values, actual package
significance, and descriptive p-value summaries. Discovery significance is
copied from the package. Positive-control tables intentionally lack
across-pair significance: the report adds neither a hit rate nor a corrected
significance field. Calibration raw-p summaries and package-corrected
rejections are distinctly labeled. Saved B1/B2/B3 values are stage budgets,
not evidence that every pair reached every resampling stage. Assignment
membership counts describe saved assignments before cell QC, not disjoint
retained-cell groups.

The frozen report view contains at most 100 scalar rows per result/QC family,
12 strongest finite-p discovery rows, 100 warning conditions and bounded
requested/resolved/provenance metadata. Full native tables, complete original
configuration/manifest and all captured warnings remain separate downloads.
Filtering changes only displayed preview rows and never scientific correction.

On a renderer failure, `report.html` becomes an explicit presentation-failure
page linking only evidence files already present. `report-status.json` still
says `failed`, and the export task still fails visibly. This fallback cannot
convert a failed analysis into a completed scientific claim.

`tests/test_report_presentation.R OUTPUT` creates real synthetic
complete/partial/failure fixtures, checks all public table/CSV/RDS values,
summary counts and p-values, correction semantics, public figures, QC failure
visibility and object/RNG immutability. Preserved examples are in
`tests/evidence/practical-parity/report-example/`; local desktop/mobile manual
Chrome screenshots and exact renderer/HTML/screenshot hashes are in
`tests/evidence/practical-parity/visual/visual-review.json`. The tested actual
CSS viewports were 1440×1000 and 390×844. These screenshots are local manual
visual evidence, not a claim that hosted CI ran a browser or that arbitrary
screens/scale were qualified.
