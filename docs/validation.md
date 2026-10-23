# Qualification status

This branch implements native schema-7 execution using selected archive SHA256
`f41a8fb7e1bc10366e8efcc7a31644d4c8356bc4eca8adda9ca949c951de4fb4`, source commit
`1e4d5459ab229255694f9217d7cd4ed51a4bf1b8`. `tests/runtime/ARCHIVE-IDENTITY.json`
and `ROOT-ADMISSION.json` retain exact package identity and original package
qualification scope. Package admission does not establish pipeline compatibility,
container execution, HPC behavior or performance of this migrated pipeline.

Schema-3 compatibility and compact execution are removed. Input objects must be
schema 7; storage is native SingleCellExperiment with in-memory sparse or native
HDF5 counts. Only `reference` and `distributed` execution modes are supported.
The package owns complete-family planning, work-unit evaluation and collection.

Historical tests, benchmark numbers, image IDs, CI badges and scheduler receipts
qualify their original artifacts only. They do not establish acceptance of this
migration. New evidence must bind the exact archive, installed implementation,
input identity, R/dependency versions, CPU architecture and runtime image.

Required comparisons include uninterrupted public-API versus pipeline execution,
complete result families and attributes, realized plans/budgets, assignments,
QC, fit reuse and RNG; distributed partition/arrival order and missing-worker
rejection; native HDF5 save/reopen/relocation; Nextflow caching and resume.
Host tests, container tests, hosted CI, Apptainer, HPC and full-screen scalability
are distinct qualification targets. No container/HPC/release qualification is
claimed by these source changes.

## Local migration checks completed 2026-10-22

The native schema-7 migration passed bounded checks on macOS ARM64 with the
selected `f41a8fb7` archive's installed package, R 4.6 and Nextflow 25.10.4
(Temurin Java 17). The [saved validation receipt](../tests/evidence/native7-local-20261022/validation.json)
records exact installed package/dependency identity and copied receipt hashes.
These are pipeline checks; earlier package qualification is a separate record.

- Nine uninterrupted-public-R versus staged pipeline cases passed.
- Eleven distributed cases passed, including native HDF5 permutations and CRT.
  Complete tables/attributes, global plans/budgets, fits, assignments, ordered
  cells/QC and continuous RNG states matched exactly. Reversed work arrival,
  missing/duplicate/corrupt proposals and partition limits 1/2/3/99 were checked.
- Actual Nextflow reference and distributed workflows passed exact public-R
  comparisons, cached resume with fresh validation, changed source/config/seed/
  array rejection, publication collision checks and configuration/parameter
  failure guards. A deliberately failed worker prevented collection/publication.
- Actual Nextflow distributed native HDF5 CRT completed all three analysis
  families and exports, then matched the uninterrupted public workflow exactly.
- Native HDF5 relocation passed with original source paths physically absent;
  staged corruption was rejected. Native CSV/RDS reporting and standalone base-R
  rerender passed. Forty Python tests and source/schema admission checks passed.

The copied R receipts and scheduler logs are in
`tests/evidence/native7-local-20261022/`. The reproducible scientific entry points
are `tests/direct-comparison.R`, `tests/distributed-comparison.R`,
`tests/ci/unit-partition-matrix.R`, `tests/native-backing-relocation.R`,
`report/check.R` and `tests/run-nextflow.sh`. Use the selected package and a fresh
output directory for each invocation; the receipt records the local dependencies.

The initial host pass did not cover container execution; the subsequent Docker
qualification is recorded below. At that local checkpoint, hosted CI,
Apptainer/HPC, full-screen scalability and new performance benchmarks were unrun.
Subsequent hosted evidence is recorded separately below; no merge or release was made.


## Exact-image Docker checks completed 2026-10-22

The native schema-7 image built successfully for Linux ARM64 with R 4.5.1 and
Bioconductor 3.22:
`sha256:b51c1cdaef908f6386b3313bd787f5d46dcc7b3f08c5fe28b271d2e5c85cd6c9`.
The [container validation receipt](../tests/evidence/native7-container-20261022/validation.json)
binds the selected archive, installed dependencies, final source hashes, image
inspection and copied logs/R receipts (including a compressed complete build log).

The final pipeline eagerly initializes the package namespace. This prevents a
reproduced package-only first-load stack warning in the R 4.5 image; the package
archive is unchanged. A fresh-process regression verifies namespace initialization
without attaching the package and exact RAM/HDF5 counts. Final same-image nine-case
direct and eleven-case distributed suites passed with zero warnings, including
native HDF5 permutations and CRT. Earlier warning-bearing evidence and its
package-only reproduction remain separately recorded in the container receipt;
the underlying package loading issue's cause was not established.

Actual Docker-backed Nextflow reference and distributed workflows passed exact
uninterrupted-public-R comparisons, cached resumes, changed source/settings and
configuration rejection, and failed-worker prevention of collection/publication.
A final-bootstrap native HDF5 CRT workflow completed calibration, power, discovery
and exports, matched public R exactly, and resumed with 16 cached scientific/export
tasks and one fresh runtime validation. Its 36 task output files contained no
stack-imbalance message.

These results qualify the bounded local ARM64 pipeline cases. They do not qualify
AMD64, hosted CI, Apptainer/HPC, full-screen scale or performance. The image is local
and was not pushed. At that local checkpoint, pipeline changes were uncommitted
and unpushed.

## Bounded hosted Linux AMD64 qualification (2026-10-23)

The public lab-fork pipeline scientific job passed all 38 mandatory nf-tests
without skips, nine direct cases, eleven distributed cases including native
HDF5 permutations/CRT, eight partition configurations, reports/demo, actual
Nextflow cached resume and source/configuration/failure guards. The exact
pipeline revision was `3c6d2c55c83f40bc02c4e262faf261273d3a8096`; the package
archive/source remain the identities at the top of this page.

A separate supported R 4.6.1/Bioconductor 3.23 package campaign at
`fb373a0c6f46ac960164a7740a2328c296f7da89` passed all 394 cases/8,109 assertions
with zero errors, warnings, failures or skips. The minimum-runtime package
suite has 15 explicit DropletUtils-version skips, which the supplemental suite
covers with DropletUtils 1.32.1. This does not claim pipeline qualification in
the newer dependency environment or cross-R-version identity.

See [CI evidence and actual Java/runtime identity](ci.md#completed-hosted-checks-2026-10-23)
and the [machine-readable hosted receipt](../tests/evidence/native7-hosted-20261023/validation.json)
for exact job links, both source revisions, artifact digests and raw output
hashes. The original workflow's overall failure is retained: its supplemental
image lacked system libuv headers. The corrected supplemental-only retry passed;
no duplicate floor campaign or misleading single-head all-green claim is made.
The branch is published to the approved lab fork; it is not merged or released.
That original baseline did not qualify Apptainer. Later bounded positive SIF evidence is recorded below; HPC, full-screen scalability and new performance benchmarks remain unrun.


## Expanded corrected-source practical parity

The expanded source preserves the selected package archive while adding public raw
preparation, predictable configuration, checkpoint continuation and rich scientific
delivery. Corrected production475e4199 passed the fresh local Docker ARM64 native
HDF5 CRT/public-R comparisons and raw launcher: exact result families, fits, design,
QC, assignments, realized plans and RNG; checkpoint continuation and cached resume;
invalid stage/family and request/source/settings guards. The separate
[corrected-source receipt](../tests/evidence/practical-parity/integrated-config/receipt.json)
records unchanged42execution/oracle files and the distinct CI-helper integration.
Both Nextflow versions additionally passed13actual config-closure invocations each,
with exact pipeline versus native-parser rejection boundaries in
[their preserved receipts](../tests/evidence/nf-core-conformance/config-closure/README.md).

The original hosted38-case baseline above does not qualify the expanded42-case
PR head. At725078e, actual isolated SIF/public-R/nativeHDF5/checkpoint/resume
and same-runtime raw launcher have passed, with55hash-bound raw artifacts in
[the current SIF receipt](../tests/evidence/practical-parity/hosted-725-39906148557/apptainer/receipt.json).
The current newer-R package-only suite passed394cases/8109assertions withzero
skips; [its raw receipt](../tests/evidence/practical-parity/hosted-725-39906148557/current-package/receipt.json)
retains that separate scope. Full minimum/current42-case scientific jobs remain
active; see
[the expanded CI record](ci.md#expanded-practical-parity-qualification). No registry,
full-screen, scheduler or new performance qualification is inferred.
