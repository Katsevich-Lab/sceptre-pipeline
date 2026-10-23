# Contributing

Use a feature branch and a reviewable pull request to the active development branch. Keep edits narrow; do not reformat frozen evidence, change the selected source archive or modify package-owned scientific algorithms in orchestration. Preserve GPL-3 provenance. Do not merge/release or publish a new container registry destination without explicit authorization.

Install isolated nf-core/tools 4.2.0 and nf-test 0.9.5. Run `nf-core pipelines lint --dir .`, `nf-core modules lint --all --local --dir .`, `nf-core subworkflows lint --all --local --dir .`, and `nf-core pipelines schema lint --dir .`. Named external-pipeline lint mappings and their scientific/branding reasons are documented in [nf-core-conformance.md](nf-core-conformance.md); do not add broad test skips.

Run actual package-backed tests with the exact built image using `tests/ci/run-nf-test.sh`, then the relevant direct-R/runtime/preparation/report checks. Source and package locks must correspond to the runtime actually executing the tests. Pipeline tests compare scientific results, fits, design, assignments, QC, family plans and RNG; successful task counts alone are insufficient. Linux/AMD64 CI and local ARM64 are different evidence. Config parsing and negative SIF checks are not positive Apptainer or cluster qualification.

Document additions in usage/output/citations/changelog, include invalid/stale/failed-path checks and report unrun limits. Follow [contributor conduct](../CODE_OF_CONDUCT.md). Report reproducible bugs through the issue form; remove credentials and private count matrices before posting logs.
