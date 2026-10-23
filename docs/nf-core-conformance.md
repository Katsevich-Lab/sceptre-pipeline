# Current nf-core engineering acceptance

Status: active implementation and qualification on `codex/nfcore-conformance-20261022`,
base `e72ae2f248c91eb83232ae71ec747a5b64f8ed67`, in a separate worktree.
The parent practical-parity goal remains active. This work does not change the
selected schema-7 scientific package archive `f41a8fb7e1bc10366e8efcc7a31644d4c8356bc4eca8adda9ca949c951de4fb4`,
source `1e4d5459ab229255694f9217d7cd4ed51a4bf1b8`, or implement a second statistical engine.

## Authority and applicability

Reviewed live 2026-10-22:

- [Official pipeline specifications](https://nf-co.re/docs/specifications/pipelines/overview)
  distinguish mandatory nf-core contribution requirements from professional
  engineering practices useful to independent pipelines.
- [Official full pipeline lint](https://nf-co.re/docs/nf-core-tools/cli/pipelines/lint)
  explicitly supports named/file-granular external-pipeline mappings in `.nf-core.yml`.
- [nf-core/tools 4.2.0](https://github.com/nf-core/tools/releases/tag/4.2.0),
  commit `3b1ae4b12bbd059ab4b1bbc072518500e5bcd368`, released 2026-10-21.
- [Docker requirement](https://nf-co.re/docs/specifications/pipelines/requirements/docker),
  [parameter conventions](https://nf-co.re/docs/specifications/pipelines/requirements/parameters),
  [single command](https://nf-co.re/docs/specifications/pipelines/requirements/single_command),
  [minimum inputs](https://nf-co.re/docs/specifications/pipelines/requirements/minimum_inputs),
  [testing](https://nf-co.re/docs/specifications/pipelines/recommendations/testing).
- [nf-test 0.9.5](https://github.com/askimed/nf-test/releases/tag/v0.9.5)
  is the latest official release checked. Minimum Nextflow remains 25.10.4;
  current stable 26.10.3 is an additional compatibility target, not a replacement
  for the qualified minimum.

The official external-organisation template was generated with tools 4.2.0 into
an isolated temporary directory for comparison. Applicable scaffold is reconciled
selectively with the existing GPL-3/source-qualified workflow. No nf-core name,
logo, ownership, approval, publication, DOI or membership is asserted.

## Acceptance matrix

| Area | Practical acceptance and evidence target | Applicability / status |
| --- | --- | --- |
| Nextflow DSL2 / modular scope | Real pipeline, module and subworkflow tests; no stub scientific tasks | Applicable; qualification in progress |
| Input and parameter contracts | Grouped titled schema, readable help, conventional `--input` alias, rejection of inconsistent inputs | Applicable; implemented, tests pending |
| Minimal/single-command usage | Zero-input synthetic `-profile test` and same-runtime project launcher | Applicable; implementation/qualification in progress |
| Containers | Immutable exact-source Docker build; real Docker comparisons; explicit engine/SIF identity | Applicable; existing Docker evidence retained, new-engine tests pending |
| Apptainer | Positive pinned Linux SIF execution and direct-R comparison, not config checks alone | Applicable; CI prepared separately, local macOS execution unavailable |
| Registry availability | A publicly pullable digest with approved visibility/architecture/source | **Pending destination-specific publication approval**; no fake registry digest |
| Resource/failure behavior | Default and label resources, site overrides, mandatory selected-stage failure, atomic scientific publication | Applicable; changes tested against package contracts |
| Version provenance | Native package/runtime hashes plus software-version topics and complete per-stage records | Applicable; in progress |
| Full pipeline lint | Actual full tools 4.2.0 run with named external mappings only | Applicable; initial run154pass/41fail/10warn after schema normalization; fixing |
| Modules / subworkflows | Current metadata schema, reusable paths/contracts, actual nf-test coverage and source-owned algorithms | Applicable; baseline0fail/57warnings; reducing actionable warnings |
| CI | Automatic lint, exact-package real tests on minimum/current Nextflow, floor/current package environments | Applicable; implementation/qualification in progress |
| Documentation | Bundled usage, output, tutorial, scientific report, contribution/release instructions and limits | Applicable; reconciled with current behavior |
| Credits/license | Cite package methods/Nextflow/nf-core inspiration and retain inherited GPL-3 | Applicable; no MIT relicensing of GPL science |
| Semantic releases | Development SemVer and reviewable release checklist; future stable tags/DOI only after authorized release | Applicable; no release requested |
| Modern file formats | Native SCE/RDS, sparse matrices, native HDF5, full CSV/native tables; no forced sequencing-specific formats | Applicable to screen inputs |
| RO-Crate / software metadata | Accurate source/runtime/workflow metadata without fake DOI/registry publication | Applicable; in progress |
| nf-core org/community/template branches | Actual nf-core governance, ownership and template-sync admission | Formal-admission scope, not claimed for this lab fork |
| Branding | Retain lab/SCEPTRE identity; no fake nf-core logo | Formal-admission scope; exact logo-file mappings only |
| Floating institutional profiles | Automatic `nf-core/configs/master` loader conflicts with immutable source/config admission | Narrow documented mapping; use explicit source-bound local site configs |
| MultiQC/email/bot comments | No such interfaces in this scientific package workflow; public scientific report and artifact diagnostics are authoritative | Specific absent-feature mappings, not substitute placeholder files |
| Full-scale/HPC/cloud | Need real target workload/executor evidence | Unrun; small local/hosted jobs do not establish these claims |

## Narrow lint mapping policy

No `pipelines lint -k` subset or broad component skip is an acceptance substitute.
The complete final pipeline lint and full local component lint must run. Named
exceptions cover external branding/governance, GPL license, absent notification/
MultiQC/cloud/bot interfaces, existing equivalent inline CI, pinned scientific
runtime boundaries and two genuine Go/Quarto template-syntax false positives.
Each mapping remains visible in lint output and must be reviewed with this matrix.
Warnings about unqualified runtime distribution remain explicit open boundaries.

## Restart and publication boundary

Continue from this branch/worktree; leave the parent parity checkout intact.
Do not rerun the old schema-3 compatibility refresh. Commits are local and
reviewable; the owning thread integrates and publishes the approved lab branch.
Registry publication is a separate, still-pending approval for
`ghcr.io/katsevich-lab/sceptre-pipeline`. A manual publication workflow may be
prepared, but no image upload, visibility change or transfer is authorized here.
