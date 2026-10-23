# Continuous integration

The workflow in `.github/workflows/nf-test.yml` checks the native schema-7 pipeline.
It verifies the selected archive before constructing a Docker context;
there is no fallback to a moving package branch or old schema runtime.

The runtime targets R 4.5.1, CRAN snapshot 2025-11-15 and Bioconductor 3.22.
The installer reads dependency declarations and enforces minimum versions from
the exact archive DESCRIPTION. Native SingleCellExperiment/HDF5 dependencies
replace ondisc. Base-image and GitHub action digests, Nextflow 25.10.4,
nf-schema 2.6.1 and nf-test 0.9.5 remain explicit in source.

Scientific checks run inside the built image: installed-package checks, native
schema admission, direct/distributed comparisons, partition guards, reports,
Nextflow execution and resume. Source configuration is a requested CI gate;
only an actual successful run qualifies the hosted platform. Historical suite
counts, badges and ARM64/Slurm receipts do not qualify this migration.

Artifacts preserve image ID/inspection, installed package versions, session info,
source receipt, scientific outputs and task logs. The source receipt binds commit `1e4d5459ab229255694f9217d7cd4ed51a4bf1b8`
and archive SHA256 `f41a8fb7e1bc10366e8efcc7a31644d4c8356bc4eca8adda9ca949c951de4fb4`;
the bundled archive-identity and package-admission receipts retain their own scope. No workflow publishes an image
or submits cluster work. System and Bioconductor release repositories may update;
preserve the actual built runtime for each qualification.

Verify identity locally without downloads:

```bash
python3 container/prepare-context.py --verify-only --source-manifest tests/runtime/source.json
```

## Hosted schema-7 qualification

The public hosted-CI destination is
[Katsevich-Lab/sceptre-pipeline](https://github.com/Katsevich-Lab/sceptre-pipeline),
a fork of `timothy-barry/sceptre-pipeline`. Its default branch is
`codex/native-schema7-hosted-ci` so the native workflow is available for manual
dispatch; the upstream `main` branch has not been merged or rewritten.
Actions are enabled. The schema and scientific jobs use `ubuntu-24.04` AMD64
runners and build the exact bundled archive locally on the runner without
publishing a container image. Bounded hosted AMD64 qualification is recorded below;
the preserved ARM64 receipts retain their separate scope.

The `scientific` job retains the minimum runtime above. A separate
`current-package` job builds R 4.6.1, Bioconductor 3.23 and CRAN snapshot
2026-10-01 from its own pinned Rocker image. It tests the same frozen package
archive with DropletUtils >= 1.32 and requires zero failed, errored, warned or
skipped package cases. It does not substitute for the minimum-runtime pipeline
checks or claim Nextflow qualification in the newer dependency environment.
The minimum-runtime package suite records its skips explicitly; Bioconductor
3.22 provides DropletUtils 1.30, so the 15 package cases requiring version 1.32
remain outside that runtime's tested coverage.

[Bioconductor 3.23 supports R 4.6](https://new.bioconductor.org/news/bioc_3_23_release/),
and its [DropletUtils release](https://bioconductor.org/packages/3.23/bioc/html/DropletUtils.html)
supplies the required maintained writer. Generate the distinct build context with
`--runtime-profile current`; each artifact preserves its own runtime metadata,
image identity, dependency versions, tests and skips.

## Completed hosted checks (2026-10-23)

The [pipeline scientific job](https://github.com/Katsevich-Lab/sceptre-pipeline/actions/runs/39894180240/job/120220918478)
passed at `3c6d2c55c83f40bc02c4e262faf261273d3a8096`: all 38 real nf-tests
passed with zero failures or skips (TAP and JUnit independently checked), nine
direct cases, eleven distributed cases including mandatory native HDF5
permutations/CRT, and eight partition configurations passed. The synthetic demo,
report isolation, real reference/distributed resume, source/configuration/seed
rejection, failed-worker and missing-family guards passed. Resume reused seven
reference and seventeen distributed scientific/export tasks, while validation
reran once. The runtime was R 4.5.1/Bioconductor 3.22 on Linux AMD64.

The [supplemental package run](https://github.com/Katsevich-Lab/sceptre-pipeline/actions/runs/39895507893)
passed at `fb373a0c6f46ac960164a7740a2328c296f7da89`: 394 installed-package
cases and 8,109 assertions passed with zero failures, errors, warnings or skips
under R 4.6.1/Bioconductor 3.23/DropletUtils 1.32.1. Both runs used the exact
archive checksum above. This retry only added the current-profile system libuv
headers and supplemental dispatch controls; it did not change the minimum
runtime or pipeline science. Its scientific pipeline job was intentionally
omitted to preserve the existing full pipeline campaign.

These are two scoped job qualifications, not one all-green workflow at one SHA.
The first workflow remains red because its additional package image initially
lacked libuv headers; the separate retry resolved that build failure. The
minimum-runtime package suite retains 15 explicit version-gated skips. All those
package paths ran without skips in the newer supported environment.

Actual engine provenance was Nextflow **25.10.4 build 11173**, nf-test **0.9.5**,
and **Zulu OpenJDK 17.0.20+8-LTS (Zulu17.68+19-CRaC-CA)**. The setup-nextflow
action selected this Java engine after the earlier Temurin setup; the earlier
Java declaration is not the tested engine identity. Source/archive, image and
native-library identities, artifact ZIP digests and raw output hashes are in the
[hosted receipt](../tests/evidence/native7-hosted-20261023/validation.json).
No full-screen benchmark, Apptainer/HPC qualification, image publication, merge
or release is established by these bounded checks.
