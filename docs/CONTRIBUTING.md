# Contributing

Use a feature branch and a reviewable pull request to the active development branch. Keep edits narrow; do not reformat frozen evidence, change the selected source archive or modify package-owned scientific algorithms in orchestration. Preserve GPL-3 provenance. Do not merge/release or publish a new container registry destination without explicit authorization.

Install isolated nf-core/tools 4.2.0 and nf-test 0.9.5. Run `nf-core pipelines lint --dir .`, `nf-core modules lint --all --local --dir .`, `nf-core subworkflows lint --all --local --dir .`, and `nf-core pipelines schema lint --dir .`. Named external-pipeline lint mappings and their scientific/branding reasons are documented in [nf-core-conformance.md](nf-core-conformance.md); do not add broad test skips.

Run actual package-backed tests with the exact built image using `tests/ci/run-nf-test.sh`, then the relevant direct-R/runtime/preparation/report checks. Source and package locks must correspond to the runtime actually executing the tests. Pipeline tests compare scientific results, fits, design, assignments, QC, family plans and RNG; successful task counts alone are insufficient. Linux/AMD64 CI and local ARM64 are different evidence. Config parsing and negative SIF checks are not positive Apptainer or cluster qualification.

Document additions in usage/output/citations/changelog, include invalid/stale/failed-path checks and report unrun limits. Follow [contributor conduct](../CODE_OF_CONDUCT.md). Report reproducible bugs through the issue form; remove credentials and private count matrices before posting logs.

## Future release checklist

A reviewed feature branch and green checks do not authorize a release. Obtain explicit release authorization before creating a release tag, GitHub release, registry publication or DOI deposit.

1. Choose the approved version and reconcile the manifest, changelog and user-facing documentation. Identify the exact candidate commit and clean tree; retain the preceding release's evidence.
2. Freeze the selected R source/archive checksum, dependency snapshots, container base/image digest and supported Nextflow/Java versions. A package or runtime change requires its own qualification; a moving image tag is insufficient.
3. Review terminal exact-source CI receipts for both supported Nextflow versions, installed-package checks, strict scientific/public-R and RNG comparisons, raw preparation, native HDF5/checkpoint/resume guards, report diagnostics and the supported container engines. Distinguish tested source from later evidence-only commits and preserve failures, skips, warning exceptions and unrun limits.
4. Rebuild/check the documentation and review representative scientific reports. Reconcile the acceptance ledger, citations, license/provenance, software versions, migration notes and any declared distribution limits. Confirm no credentials, private data or unrelated artifacts enter the candidate.
5. Present the concrete candidate version/commit, proposed tag, release notes, image destinations and evidence to the authorized maintainer. Create only the specifically approved tag/release and DOI deposit; registry destinations and public visibility require their own authorized scope. Read back the resulting tag, archive/checksums, published digest and DOI metadata.
6. Verify the documented installation/download path from the published immutable identities, including an unauthenticated image pull if public distribution is claimed. Record the final publication receipt and any unresolved limitations before announcing availability.

This checklist prepares a future maintainer decision; the current practical-parity work includes no merge, tag, release or DOI publication.
