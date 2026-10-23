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
| Nextflow DSL2 / modular scope | Real pipeline, module and subworkflow tests; no stub scientific tasks | Applicable; bounded modules/default smokes passed; full final-head CI remains the acceptance gate |
| Input and parameter contracts | Grouped titled schema, readable help, conventional `--input` alias, rejection of inconsistent inputs | Applicable; actual schema/preflight/public-R input suites passed; final integrated CI repetition remains |
| Minimal/single-command usage | Zero-input synthetic `-profile test` and same-runtime project launcher | Applicable; actual launcher and bounded workflow receipts passed; final integrated CI repetition remains |
| Containers | Immutable exact-source Docker build; real Docker comparisons; explicit engine/SIF identity | Applicable; real Docker and current-source positive SIF passed; registry/public pull remains pending approval |
| Apptainer | Positive pinned Linux SIF execution and direct-R comparison, not config checks alone | Applicable; actual hosted725 SIF/direct-R/checkpoint/launcher passed; macOS SIF execution and HPC remain unqualified |
| Registry availability | A publicly pullable digest with approved visibility/architecture/source | **Pending destination-specific publication approval**; no fake registry digest |
| Resource/failure behavior | Default and label resources, site overrides, mandatory selected-stage failure, atomic scientific publication | Applicable; changes tested against package contracts |
| Version provenance | Native package/runtime hashes plus software-version topics and complete per-stage records | Applicable; implemented, final qualification in progress |
| Full pipeline lint | Actual full tools 4.2.0 run with named external mappings only | Applicable; complete tools4.2.0 lint195pass/0fail/2warnings (name and directory MIME),38 ignored diagnostics visible in raw output |
| Modules / subworkflows | Current metadata schema, reusable paths/contracts, actual nf-test coverage and source-owned algorithms | Applicable; full local modules245pass/0fail/28warnings; subworkflows42pass/0warn/0fail |
| CI | Automatic lint, exact-package real tests on minimum/current Nextflow, floor/current package environments | Applicable; actual launcher and bounded workflow receipts passed; final integrated CI repetition remains |
| Documentation | Bundled usage, output, tutorial, scientific report, contribution/release instructions and limits | Applicable; reconciled with current behavior |
| Credits/license | Cite package methods/Nextflow/nf-core inspiration and retain inherited GPL-3 | Applicable; no MIT relicensing of GPL science |
| Semantic releases | Development SemVer and reviewable release checklist; future stable tags/DOI only after authorized release | Applicable; no release requested |
| Modern file formats | Native SCE/RDS, sparse matrices, native HDF5, full CSV/native tables; no forced sequencing-specific formats | Applicable to screen inputs |
| RO-Crate / software metadata | Accurate source/runtime/workflow metadata without fake DOI/registry publication | Applicable; implemented, final qualification in progress |
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

## Current parser and component diagnostics

[Official strict-syntax migration](https://docs.seqera.io/nextflow/strict-syntax)
and [nf-core migration guidance](https://nf-co.re/docs/developing/migration-guides/strict-syntax)
were checked against actual Nextflow26.10.3. Recursive closure capture, increment,
array allocation/stream loops and the profile-dependent array directive required
real source migration. The source now passes strict lint with no errors; seven
warnings concern `when` sections that the tools4.2.0 module template still
requires and Nextflow26.10 deprecates. They are retained to support the minimum
runtime while enforcing an explicit failure for false `ext.when`; workflow
empty-state/delivery guards separately reject missing selected work.

The28 module diagnostics are seven each for Docker/Singularity container
identities supplied by the shared immutable runtime profile, an absent optional
Conda environment, and mandatory selected-stage `when` conditions that raise an
error instead of silently skipping requested science. All naming and metadata
mismatches were fixed: local modules have canonical alphanumeric directories and
process declarations, with explicit aliases preserving the existing SCEPTRE_*
workflow task identities and scheduler/publication selectors.

The container identity diagnostics remain tied to pending approved immutable
runtime distribution. The optional Conda runtime is **unsupported and unqualified**,
not technically impossible: a separately built exact-archive recipe could be
implemented and tested later. The [pipeline Docker requirement](https://nf-co.re/docs/specifications/pipelines/requirements/docker)
recommends Bioconda where possible; this implementation currently qualifies its
central exact-source Docker image instead. The [module software specification](https://nf-co.re/docs/specifications/components/modules/software-requirements)
requires a module-directory Dockerfile for non-Bioconda software contributed as a
standalone nf-core component. This lab pipeline has one real central
`container/Dockerfile` plus `prepare-context.py`, preserving the same archive and
public-package implementation across every stage. That is the actual reproducible
recipe, but it does **not literally meet the standalone contributed-module file
location convention**. No formal component-specification conformance is claimed.
Seven duplicate recipes are not introduced merely to imply that claim.

The pipeline-name warning preserves the existing lab repository identity. The
native certified directory input has no sequencing-file MIME and is not labeled
CSV. All remaining diagnostics stay visible in complete lint output; zero
failures alone is not described as complete nf-core admission or qualification.

An initial minimum-runtime exploratory nf-test campaign completed seven exact
scientific comparisons and was intentionally terminated by SIGTERM (exit143)
before strict-parser fixes; it is not the final suite receipt. The current strict
launcher smoke completed nativeHDF5 CRT distributed discovery, exact public-R
comparison, unchanged scientific cache reuse and source/settings mutation guards.
The final source snapshot and complete suite results are recorded separately.

## Frozen integration campaign

The final canonical source snapshot records production identity
`2a8b4a88ce8b2f653c7f9dee1ba246bd6a56c7bf69aa5b0433e3ad47cf90b40e`
and independent qualification/oracle/setup identity
`c067146080f7ebf66f50546d80dd5072a7058af561e769113e9256cfa1584b6b`.
The lead integration checkout and conformance checkout matched both before the
campaign. The final42-case minimum25.10.4 supported-default suite runs separately from
lead full nativeHDF5 CRT/checkpoint/resume and raw-project launcher runs. Terminal
receipts, rather than this in-progress note, determine which checks passed.

## Supported parser defaults and experimental diagnostics

The [versioned primary guidance](https://docs.seqera.io/nextflow/strict-syntax)
states that Nextflow25.10 uses parser v1 by default, while26.04 and later use v2.
The official tools4.2.0 generated test workflow and composite action do not force
v2 on the minimum25.10.4 matrix. Accordingly, the supported acceptance matrix
uses25.10.4's documented default and26.10.3's strict default; strict current source
lint remains mandatory. This does not disable the current parser.

An extra25.10.4 experiment with opt-in `NXF_SYNTAX_PARSER=v2` completed seven
exact scientific comparisons, but external `-c` overrides lost named profiles;
its profile/array configuration acceptance checks failed. It was deliberately
terminated by SIGTERM(exit143) rather than used as minimum-runtime qualification.
The same25.10.4 override under its supported default correctly rejected disabled
selected stages before publication. Full required42-case execution was restarted
with the experimental override unset. The scientific production identity did not
change; CI setup identity changed to record the supported parser contract and
explicit PR-head checkout/artifact capture.

Supported-default bounded acceptance is now terminalPASS:25.10.4 3/3 and26.10.3
3/3, zero skips, each with identical source/oracle before and after. Cases execute
real zero-input preparation plus all reference families, the certified input alias,
and rejection of incomplete explicit inputs. Exact source/qualification hashes
and TAP/XML/logs are preserved at `tests/evidence/nf-core-conformance/bounded-*`.
Supported-default minimum selected-stage override and current conflicting-input/
selected-stage guards passed separately. The original full42-case floor campaign is terminal exit1:39 passed and3 failed.
All three failures were stale SCEPTRE orchestration fixtures supplying13 channels
to the current14-channel interface; all four analysis-subworkflow cases passed,
including invalid-channel guards. Original failed TAP/XML/logs and identical
before/after source maps are retained under
`tests/evidence/nf-core-conformance/supported-minimum-42-original`.
The corrected orchestration fixtures passed3/3 focused real Nextflow/public-R
cases with zero skips (commitf3e59e1). Their full science/RNG and omitted-stage
assertions are unchanged. This does not retroactively make the original42-case
campaign pass. The final
hosted minimum/current matrix remains the full integrated acceptance authority.

## Hosted lint and CI action provenance

The exact earlier review head50b2a5d completed hosted engineering run39899165626.
Its full pipeline JSON records153 passed,38 ignored,2 warnings,0 failures and1
in-memory fixed item; the CLI aggregate reports195 passed after including42
subworkflow checks. The fixed item is tools4.2.0's `rocrate_readme_sync`: it adds
README description text to an in-memory root RO-Crate descriptor and records a
fix before its equality check; it does not persist a source edit in this case.
The checkout remained clean. This receipt therefore does not claim zero fixes.

The later CI-only action audit is retained under
`tests/evidence/nf-core-conformance/action-runtime-audit`, including official
release SHAs and downloaded action metadata with hashes. Direct JavaScript
actions moved to current Node24 releases; setup-nextflow3 also removed its old
nested mutable checkout. Its explicit Temurin17.0.10+7 input corrects the old
composite's effective Zulu17 override. That is a real CI runtime correction,
requiring the subsequent hosted campaign; the earlier hosted success cannot
qualify the new JVM setup. Publication-workflow OCI labels are prospective
repository/revision metadata only: no registry image was published by this audit.

The next hosted engineering run39900277687 also completed successfully on exact
head84590ae4b4966d224a66b203b7c20e29c60632a0. Its post-composite engine assertion
verified Temurin17.0.10+7 and Nextflow25.10.4 with no parser override. Raw pipeline
counts remain153passed/38ignored/1in-memory fixed/2warnings/0failures; module
counts245passed/28warnings/0failures and subworkflow counts42passed/0warnings/
0failures. The explicit26.10.3 strict-lint step passed with23files without errors
and7when-deprecation warnings; it has no separate26.10.3 identity JSON. Exact
source maps, artifact hashes, terminal status, original compressed logs and
runtime receipts are retained under
`tests/evidence/nf-core-conformance/hosted-engineering-39900277687`. The paired
scientific run39900277427 was canceled, not passed. This engineering success does
not qualify the later corrected full scientific matrix or imply container/HPC/
registry execution.

## Complete configuration include identity

Configuration traversal starts at every Nextflow-reported root, including tracked
`nextflow.config` and tracked profile/resource files. A tracked file remains part
of the traversal even though its own bytes are already in production identity;
only the final external digest list filters already-bound production files.
This closes tracked→external and external→tracked→external include chains.
The traversal conservatively binds every literal profile/conditional branch,
not only branches selected for execution. External config bytes are hashed on
the host; they are not copied into the scientific container.

Only local literal include paths are supported for identity. Inline profile
blocks, parenthesized literals, ordinary next statements, and comments are
handled; interpolation, variable paths and expression continuations are rejected.
Comments are whitespace rather than statement terminators, so comment-separated
concatenation, method calls and string repetition cannot bind a literal prefix.
Quoted/comment text is not an include call; a hidden include in an interpolated
string fails closed (current Nextflow may reject it during native parsing first).
This is a conservative supported-config contract, not a general Groovy evaluator.
The mandatory `tests/ci/check-config-closure.py` runs on both Nextflow CI versions:
exact external-leaf digest admission, unchanged resume, leaf-mutation rejection
without changed certified publications, plus seven expression-rejection cases.

The corrected closure is qualified locally on25.10.4 and26.10.3:13actual
Nextflow invocations each, with exact positive digest/cache/publication checks
and seven explicit negative expression cases. Raw receipts and final source
identities are retained at `tests/evidence/nf-core-conformance/config-closure`.
This historical closure milestone has production475e4199, superseding2a8b4a88.
The later caller-owned Docker correction is production98522279; its exact current
source/CI receipts are recorded in [the acceptance ledger](parity-acceptance.md). The mandatory CI helper runs both matrix versions and preserves
its receipts; the lead reruns full nativeHDF5 science separately.
