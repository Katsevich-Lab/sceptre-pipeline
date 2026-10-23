# nf-core engineering contracts

This independent laboratory pipeline applies the current nf-core engineering
specifications. Formal nf-core organisation admission, branding and ownership are
separate and are not claimed. The scientific owner remains the selected schema-7
SCEPTRE package; Nextflow schedules and validates certified artifacts.

The [current conformance ledger](nf-core-conformance.md) records the official
sources, applicability matrix, exact tool identities, actual check results and
remaining boundaries. Full nf-core/tools 4.2.0 pipeline lint, local module and
subworkflow lint are acceptance checks. Named external-pipeline mappings preserve
GPL licensing, genuine lab identity, immutable configurations and the actual
scientific report interface; they are visible in lint output.

## Implemented engineering boundaries

| Contract | Implementation and executable check |
| --- | --- |
| Modular DSL2 | Public stage, validation, prepare/worker/collect and export modules; full module/subworkflow/native workflow nf-test suites |
| Early typed admission | nf-schema2.7.3 grouped schema/help; exact runtime/config/object/source checks before science; negative-input tests |
| Minimal test inputs | `-profile test,docker` generates synthetic inputs in the selected image; explicit incomplete inputs reject rather than silently generate data |
| Same-runtime single command | `bin/sceptre-pipeline` prepares raw JSON projects with public R and launches Nextflow in that same immutable Docker image or checksum-pinned SIF |
| Reproducible runtime | Bundled exact package archive, immutable base image, snapshot/dependency receipt, installed-package identity; no moving runtime tags |
| Resources and failure | Label defaults and site overrides; zero automatic retries; atomic completed states; false `ext.when` raises an explicit error rather than silently erasing a selected stage |
| Provenance | Certified manifests, versions topics and `pipeline_info/software_versions.yml`, per-stage records, runtime/source/config hashes, trace/report/timeline/DAG |
| Exact science and resume | Whole-family public calls, package-owned RNG/fit reuse/integration/multiplicity; direct-R comparisons, worker proposal guards, checkpoint and unchanged resume tests |
| CI | Automatic full lint and native tests on minimum25.10.4/current26.10.3 Nextflow; separate floor/current package environments and positive isolated Apptainer job |
| Reporting | Public scientific plots/tables and explicit omitted stages/warnings, portable HDF5 output/reopening; report errors remain separate from certified science |

## Reproduce the checks

From the repository root with Docker running, Java and Nextflow installed:

```bash
bash container/build-bundled.sh
export SCEPTRE_CONTAINER_IMAGE=$(cat container/.build/bundled/image-id)
export NXF_VER=25.10.4
nextflow run . -profile test,docker --container_image "$SCEPTRE_CONTAINER_IMAGE" --outdir /absolute/fresh/results
bash tests/ci/run-nf-test.sh /absolute/tools/nf-test-0.9.5.jar /absolute/fresh/nf-test
bash tests/ci/check-selected-stage-gate.sh /absolute/fresh/selected-stage-guard
bash tests/run-parity-nextflow.sh /absolute/fresh/native-hdf5-crt
bash tests/run-launcher.sh /absolute/fresh/raw-project
nf-core pipelines lint --dir .
nf-core modules lint --dir . --all --local
nf-core subworkflows lint --dir . --all --local
```

Use nf-core/tools4.2.0 and nf-test0.9.5. `NFT_WORKDIR` is the current test workdir
override; the older `SCEPTRE_NFTEST_WORKDIR` remains accepted. The CI driver creates
all public synthetic fixtures and locks in the exact tested Docker runtime,
enables distributed coverage, and rejects failed, missing, skipped or TODO
acceptance cases. No scientific process is replaced by a stub. File coverage is
an inventory metric, not evidence that tests executed or numerical results matched.

The `test_full` profile exercises every distributed scientific family on bounded
synthetic data. It is not a full-screen scalability benchmark. Slurm resources
and worker arrays remain site opt-ins; local configuration checks do not establish
execution on a cluster. Positive Apptainer CI is distinct from static SIF guards,
and requires a successful hosted run before SIF support is described as qualified.
[Container publication](container-publication.md) remains a separate approval and
public digest-pull boundary; local reproducible builds require no registry upload.

## Scientific ownership

Reference mode calls each complete family through the public package API.
Distributed mode freezes the package execution certificate, scatters whole-key
units into unfinalized proposals and checks exact coverage before the collector
commits one whole family. Workers reopen backing locally; no live contexts or
cached draws are serialized. RNG state passes across stages unchanged, and the
package owns native sampling seeds. Arbitrary per-partition seeds are not an
equivalent statistical contract. Resume binds the original session, settings,
runtime, source closure, input/config and selected execution options; changed
scientific or implementation identities require fresh publication paths.

## External site configuration identity

`workflow.configFiles` omits nested includes. The adapter recursively hashes the
closure of standalone literal local `includeConfig` paths in external site files,
relative to each including file. Unchanged nested configuration must resume with
cached science; modifying a child file rejects publication reuse. Dynamic,
interpolated, remote and conditional include expressions reject explicitly before
scientific tasks. Select separate literal site files/profiles instead. Production
configs remain covered by the full source manifest and retain their normal profile
syntax. No raw external configuration is staged in workers. Missing includes and
cycles fail in Nextflow's configuration parser before workflow startup; its 25.10.4
cycle diagnostic is `StackOverflowError`. Tests cover these failures as well as
unsupported ambiguity. This constrained site-config interface is not general HPC,
cluster, cloud or Apptainer qualification.
