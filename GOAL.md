# Practical parity goal

Bring the Nextflow pipeline to practical feature parity with the qualified schema-7 R SCEPTRE package, preserving package-owned science and RNG and a consistent scientific experience. Deliver tested source, documentation, receipts and hosted CI at the approved public Katsevich-Lab/sceptre-pipeline repository. No merge/release.

## Authority and restart boundary

2026-10-22: Eugene explicitly requested full delegated implementation. Initially local-only pending concrete publication approval. Subsequent direct user approval ('I already approve') covers expanded practical-parity source/docs/tests/receipts and necessary package archive at the same public lab repository, feature branch codex/practical-parity-20261022, and hosted CI through failure fixes. Publication gate is met; preserve unrelated work and data/secrets.

Base 115b5eb; qualified R product 1e4d5459ab229255694f9217d7cd4ed51a4bf1b8, archive f41a8fb7e1bc10366e8efcc7a31644d4c8356bc4eca8adda9ca949c951de4fb4. Baseline CI is independently owned. Work only in this checkout. Experimental R features are future gates, not baseline.

## Acceptance ledger

| Workstream | Acceptance | Status |
|---|---|---|
| Configuration | reproducible typed authoring/preflight, requested/resolved defaults, omitted/partial settings and explicit errors | implemented; focused tests pass, final frozen run pending |
| Inputs | public matrix/SCE/10x/CellRanger/Parse entrypoints, source hashes, alignment, RAM/HDF5 | implemented; direct-R import tests pass |
| Pairs | explicit/cis/trans/positive public construction with frozen input identity | implemented; public pair comparisons/guards pass |
| Scientific delivery | public plots, full pair QC, warnings, report isolation | implemented and focused tests pass; richer visual acceptance in progress |
| Persistence | portable backing manifest/reopen/current checkpoint reuse with identity/currentness guards | implemented; relocation/guard and exploratory actual checkpoint comparisons pass |
| Resources | actionable bounded admission, no scientific fallback, measured bounded evidence | implemented limits/observed component sizes; final Docker trace evidence pending |
| Documentation | current HDF5/recovery/site and consistent scientific contract | updated; site links pass; final rebuild pending |
| Qualification | meaningful direct R/path/error/relocation/resume local tests; hosted CI separate source identity | pending |

Missing arbitrary-scale/HPC assurance is not represented as completed by bounded tests. No second statistical engine or Python edits. Public R contract blockers are escalated; don't bypass identities.

## Added user acceptance: actual current nf-core engineering criteria

2026-10-22: Eugene additionally requested current nf-core conformance across applicable pipeline/module/subworkflow/container/schema/test/CI/documentation/provenance/community/release engineering. This extends the unfinished goal. A dedicated conformance lane reuses the delivery child in separate `sceptre-pipeline-nfcore` worktree from e72ae2f, branch `codex/nfcore-conformance-20261022`; it must source official current guidance, evaluate nf-core/tools 4.2.0 (release 2026-10-21), run full applicable lint and fix failures with only narrow officially justified external-project exemptions. Preserve inherited GPL license, independent project identity, exact science/runtime contracts and report quality. No formal nf-core organization admission, transfer, submission or fake branding. Actual HPC/Apptainer execution stays distinct from config/static checks. Integrate and validate these changes before final expanded publication; no additional user approval required for the already-authorized lab branch/CI.

Registry distribution acceptance: prepare a manual exact-source publication workflow for `ghcr.io/katsevich-lab/sceptre-pipeline` and immutable image/digest/provenance/anonymous-pull verification. Actual registry publication/visibility changes remain pending a destination-specific approval; the already-approved lab Git branch/CI scope does not authorize this new registry destination. Do not treat this distribution gap as inapplicable or claim full container conformance before it is resolved.
