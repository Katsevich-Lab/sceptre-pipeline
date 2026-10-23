# Practical parity with qualified R SCEPTRE

The pipeline uses the exact schema-7 source recorded in `tests/runtime/source.json` (qualified product `1e4d5459`, archive SHA256 `f41a8fb7e1bc10366e8efcc7a31644d4c8356bc4eca8adda9ca949c951de4fb4`). It calls public R import, pair construction, parameter, assignment, QC, complete-family execution and persistence functions. No second statistical engine or legacy storage adapter is present.

## Prepare raw data and scientific configuration reproducibly

The single-command launcher prepares the declared raw inputs inside the selected immutable container and launches Nextflow with that same installed runtime and lock. It needs Python, Java/Nextflow and Docker (or a local Apptainer SIF), **not host R**:

```bash
bin/sceptre-pipeline --data-root /absolute/screen-data \
  --input-json /absolute/screen-data/input.json \
  --analysis-json /absolute/screen-data/analysis.json \
  --run-dir /absolute/new-run --container-image sha256:QUALIFIED_IMAGE_DIGEST \
  -- --execution_mode distributed --n_work_units 4
```

The launcher defaults to Nextflow25.10.4, or respects an exact `NXF_VER` selected by the caller/CI matrix; that engine identity is bound to resume. Moving `latest` selectors are rejected. All JSON/referenced raw inputs must be inside the explicit read-only data root; the new run directory must be outside it. The launcher mounts only the code, declared data root and run root. It checks the image's exact source/archive/schema receipt before import. `run/prepared` retains source hashes/config/lock/backing and `run/results/exports/scientific-report/report.html` is the scientific report. `run/results/pipeline_info/report.html` is the distinct execution report.

Use the **same command plus `--resume` before the final `--` separator** for an unchanged retry. The launcher verifies its own code/JSON/argument/image identity and the original JSON/reference files plus declared raw-directory inventory before allowing Nextflow resume. Native count backing is admitted separately against the frozen staged copies and package content anchors; resume uses those immutable prepared counts. Changed source/config needs a new run directory. A failed scientific task keeps its native logs and previously certified stage artifacts; no successful family is fabricated.

For a checksum-qualified SIF use `--engine apptainer --container-image /absolute/runtime.sif --container-image-sha256 SHA256`. Additional site profiles use `--profiles slurm,apptainer` or the appropriate engine/site combination. Preparation runs on the invocation host, not a scheduler worker: invoke inside a suitably resourced allocation for large imports. Scientific tasks then follow the selected site profiles. Actual local Docker and hosted SIF qualification remain separately named; supporting an engine flag does not establish HPC execution.

The two-step preparation interface remains useful for reviewing settings before spending on the scientific workflow:

Run the shipped helper **inside the same immutable package runtime** that will execute Nextflow:

```bash
Rscript --vanilla bin/prepare_project.R input.json analysis.json prepared-screen
nextflow run . -params-file prepared-screen/params.json --outdir results
```

For Docker, mount the project, source data and new output parent at identical absolute paths, set the working directory to the pipeline checkout, and run the helper in the qualified image. The prepared lock describes that installed runtime; a host-R lock cannot be transplanted into a different container. Then add `-profile docker --container_image sha256:...` to the Nextflow command.

Both JSON files are data, never sourced as R code. Ordinary objects are named R argument lists. Arrays are vectors. Explicit references are `{"$rds":"counts.rds"}`, `{"$table":"guides.tsv"}` (headered TSV), and `{"$formula":"~ batch + z"}`. Paths are relative to their containing JSON file. RDS is a trusted local format: use files you control. RDS preserves sparse/native matrices, typed factors, data frames and complex formulas; TSV uses ordinary R type inference and cannot preserve arbitrary factor contrasts. For cell-indexed covariates use `{"$table":"covariates.tsv","row_names":"cell_id"}`: the unique ID column becomes row names and is removed from covariates. Imported order must already match counts; the helper never reorders rows. JSON formulas use a base environment; provide a trusted formula RDS when local function environments are required. Nothing silently aligns or renames cells/features.

Example `input.json`:

```json
{
  "method": "matrix",
  "arguments": {
    "response_matrix": {"$rds":"responses.rds"},
    "grna_matrix": {"$rds":"guides.rds"},
    "grna_target_data_frame": {"$table":"guide-targets.tsv"},
    "extra_covariates": {"$rds":"cell-covariates.rds"},
    "moi": "high",
    "use_hdf5": true
  },
  "analyses": ["calibration", "power", "discovery"],
  "seed": 271828
}
```

Example `analysis.json`:

```json
{
  "analysis": {
    "discovery_pairs": {"$table":"discovery.tsv"},
    "positive_control_pairs": {"$table":"positive.tsv"},
    "formula_object": {"$formula":"~ batch + z"},
    "resampling_mechanism": "crt",
    "resampling_approximation": "skew_normal",
    "grna_integration_strategy": "union",
    "multiple_testing_method": "BH",
    "multiple_testing_alpha": 0.1
  },
  "assignment": {"method":"thresholding", "threshold":5},
  "execution": {"output_amount":2},
  "resources": {"max_cells":1000000,"max_design_bytes":1000000000}
}
```

The remaining `qc` and `calibration` sections use public R argument names. Existing typed RDS configs remain supported; the JSON helper does not narrow their scientific options. For a complete trusted config use `{"$rds":"analysis_config.rds"}` as `analysis.json`.

### Supported preparation paths

| `method` | Public function | Main arguments and storage contract |
|---|---|---|
| `matrix` | `import_data` | `response_matrix`, `grna_matrix`, guide metadata, explicit `moi`, optional full aligned covariates/response labels; RAM by default or explicit `use_hdf5` |
| `sce` | `import_from_sce` | SCE RDS, guide metadata, `moi`, assay/altExp names and selected covariate columns; native RAM/HDF5 seeds preserved |
| `tenx` | `import_data_from_10x` | ordered `samples` paths to 10x directories/HDF5, guide metadata, `moi`, optional covariates/block/compression; native HDF5 |
| `cellranger` | `import_data_from_cellranger` | ordered `directories`, guide metadata, `moi`, covariates; RAM or explicit HDF5 |
| `parse` | `import_data_from_parse` | `gene_mat_fp`, `grna_mat_fp`, `all_genes_fp`, `all_grnas_fp`, guide metadata, `moi`, covariates; the public API imports to RAM and has no HDF5 switch |
| `object` | `read_sceptre_object` | `file` and optional identity-matched native replacement matrices; schema 7 required, package validates backing anchors |

The helper owns `directory_to_write` and atomically publishes the project only after import and preflight succeed. Source JSON, referenced files and raw directory contents are hashed before use and checked after import. `preparation.rds` records import method, source hashes, package identity, constructed-pair settings and the exact generated `params.json` hash. Unchanged launcher resume verifies these request bytes, including seed, selected analyses and input paths, before submitting Nextflow. `backing/` contains immutable content-addressed native files; `input/manifest.rds` binds original descriptor paths and their hashes so they can be relocated without rewriting package identities. Keep the complete prepared directory. A changed JSON/reference/raw source during preparation rejects publication.

Import preserves public R ordering, metadata validation, full-library covariates and vector aggregation. Generic matrices are supplied as native R matrix RDS; raw 10x/CellRanger/Parse files use their public importers. The pipeline does not invent normalization, count filtering, ID remapping or a new raw-file parser.

## Construct the same hypothesis family

Explicit discovery/positive-control tables belong in `analysis`. Alternatively, place public constructor requests in `input.json`:

```json
"pairs": {
  "positive_control": {"method":"positive_control"},
  "discovery": {
    "method":"cis",
    "assembly":"GRCh38",
    "arguments": {
      "response_position_data_frame":{"$table":"frozen-response-positions.tsv"},
      "distance_threshold":500000
    }
  }
}
```

`trans` accepts the public `pairs_to_exclude` values `none`, `pc_pairs`, `pairs_containing_pc_targets`. Constructed positive controls are passed to discovery construction unless explicitly supplied there. Cis requires frozen response coordinates and a nonempty assembly label; guide coordinates come from imported guide metadata. The label records a declaration, not independent verification of genome assembly. Annotation bytes, distance and exclusions are frozen in preparation provenance. Tables and row order come directly from R. Empty constructed families, unknown IDs and ambiguous duplicate settings reject rather than substituting another family. Negative calibration families remain package-generated using public calibration arguments; explicit negative-pair override is not a public R capability.

## Omitted, partial and resolved settings

`analysis` is a **complete public `set_analysis_parameters()` call**: specifying only alpha resets omitted pairs/formula/side to R defaults. Omitting the whole section preserves an already configured current object. Omitting assignment config reruns R's MOI-specific default, except existing current external assignments are preserved; supplied method-specific arguments are validated before execution. No silent adaptation from thresholding parameters to mixture is allowed.

Low MOI defaults to NT controls/permutations; high MOI defaults to complement/CRT. The selected R package resolves even explicit high-MOI `nt_cells` to complement. Preflight records a conspicuous note; it does not pretend the request was honored. R and Broad Python differ in this request behavior (Python rejects it). Formula/design, side, integration, approximation, alpha/correction and method names retain their R meanings. B1/B2/B3 are package-owned rather than user budget knobs. Complete-family correction occurs in the package collector; worker fragments are never independently corrected.

`prepared-screen/settings.json` and each workflow's `resolved_settings.json` show requested/resolved values, design identity, selected analyses and resource bounds before scientific tasks. Use `bin/preflight.R BUNDLE CONFIG LOCK BACKING calibration,power,discovery` independently. Missing pairs for a selected family reject early. The chosen analyses execute in canonical order; stage omission is explicit and affects random-stream history. Calibration requires active post-QC non-targeting guides and is not a prerequisite for discovery.

## Reuse a certified checkpoint

For an unchanged workflow use normal `-resume SESSION_ID`. To start a **new** workflow at an existing current stage bundle:

```bash
nextflow run . --input_bundle previous/qc/state --checkpoint_stage qc \
  --analysis_config prepared/analysis_config.rds --environment_lock prepared/environment_lock.rds \
  --backing_directory prepared/backing --analyses discovery --seed 271828 --outdir continued
```

Allowed checkpoint stages are parameters, assignment, QC and completed analysis families. The bundle must have the exact config/runtime/seed/import/family identity and continuous serialized RNG; public assignment/QC/result getters validate package currentness. Already completed families cannot be selected again or reordered ahead of prior families. Checkpoint reuse never reconstructs preparation, changes config, fabricates completion flags or edits package provenance. The new workflow records its own pipeline source signature; retain the predecessor run signature and stage manifests for full orchestration lineage. Exact pipeline/site-source equality is required for unchanged `-resume`, whereas a new checkpoint run certifies the saved scientific package/config/RNG state under the current workflow source. A config change needs a new input/project; arbitrary imported QC objects and private cache surgery are not supported.

## Delivery, resources and qualification

See [scientific delivery](scientific-delivery.md) for public plots, working-pair QC reasons, distributed warnings, presentation isolation and portable native HDF5 outputs. Export now requests the medium resource label by default; sites can override allocations explicitly.

Optional `resources` limits cap `max_cells`, `max_requested_pairs`, `max_design_bytes`, `max_backing_bytes`, and preparation `max_source_bytes`. Exceeding one rejects with the measured component and declared allowance; no method/budget/backend/family changes automatically. Bounds are necessary components, **not peak RSS predictions or arbitrary-scale admission**. Read per-stage Nextflow trace wall time/peak RSS, and [scale boundaries](scale-boundaries.md) before choosing concurrency. Import may allocate before its dimensions are known; `max_source_bytes` checks decoded configuration and subsequent count-file references before loading them and checks raw files before public import; configuration decoding itself and already supplied in-memory objects are not peak-memory bounded. Other caps run once R resolves data/design. Source-file bytes do not predict matrix memory. Public pair constructors may materialize the requested family before its post-construction row cap can be checked; a cap is not pre-allocation memory assurance. Use the scalar pilot admission tool before very large family construction. Existing `resource_admission.py` supplies conservative scalar pilot checks when full dimensions/budgets are known.

The branch's acceptance ledger and receipts distinguish direct-R/import/error/relocation/checkpoint tests, actual bounded workflow execution and hosted CI. Bounded positive hosted Apptainer execution has its own source-bound receipt. Full Gasperini/Replogle, arbitrary scale, cluster schedulers and new performance qualification remain separate unrun claims. Safe-targeting annotations, Wilcoxon and experimental CPU/GPU lanes are not this baseline: expose them only after public R adoption and executor/QC/result/correction qualification. The pipeline must never switch association method to meet a resource limit.

## Cross-surface scientific contract

Nextflow is an idiomatic orchestration surface for these R semantics. Broad Python remains a distinct implementation; the comparison below binds the audited source snapshot `7adaa9f`, not every later Python version. The wrapper does not erase these differences.

| Meaning | R / Nextflow | Broad Python comparison / interchange rule |
|---|---|---|
| Controls and MOI | MOI explicit at import; low defaults NT/permutations, high complement/CRT; high-MOI explicit NT resolves to complement and is reported | Audited Python defaults high MOI and rejects high-MOI explicit NT. Transfer explicit MOI and resolved controls, never interpret those requests as identical. |
| Design | Package creates exact R formula design, factor levels/contrasts/interactions and aligned cell IDs | Python accepts numeric design and 0-based assignment indices; transfer design columns/contrasts/cell IDs and index convention, not formula text alone. |
| Correction and alpha | Package corrects integrated complete discovery/calibration family with chosen p.adjust and strict `< alpha`; positive-control power is not across-pair significance | Audited Python returns uncorrected p-values; alpha helps determine empirical draws. Raw p-values must not be labeled R/NF discoveries or corrected significance without a defined family/correction step. |
| Effect values | Original R `fold_change`, `se_fold_change`, `log_2_fold_change`, IDs/QC/diagnostics are preserved | Python percentage change is `100*(fold_change-1)`, not log2 change. Label effect/SE scales explicitly; do not rename SE across scales. |
| Calibration and power | Calibration samples negative-control family; power checks supplied positive-control p-values/effects using public plots | Analytical prospective power is a separate quantity. Freeze actual negative family and realized budget when comparing, not just a count/seed. |
| Draw budgets | R empirical discovery/power budget uses maximum eligible discovery/positive family size; pipeline uses exact public plan | Audited Python sizes its current per-call family. Same nominal approximation/alpha may imply different budgets; transfer realized B1/B2/B3/family sizes. |
| RNG | Continuous serialized package-owned R state, canonical selected stages, shared whole-key draws and full-family collection | Python per-call seeds are not a cross-language draw identity. Same integer seed alone does not establish equivalent draws or exact results. |

The scientific report is distinct from the Nextflow execution report (task/runtime metrics) and benchmark reports (measured implementation comparisons). Its positive-control section reports real p-values/effects and the package plot; it does not invent an FDR hit rate where the public power result has no significance column. All-omitted/unavailable/failed stages are explicit.

See the [acceptance ledger](parity-acceptance.md) for the complete capability matrix, intentional exclusions, future adoption gates and exact qualification boundaries.
