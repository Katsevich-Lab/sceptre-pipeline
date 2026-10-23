# Hosted engineering lint39900277687

Terminal **SUCCESS**, exact checkout
`84590ae4b4966d224a66b203b7c20e29c60632a0`, hosted Ubuntu24.04 LinuxAMD64.
[Run](https://github.com/Katsevich-Lab/sceptre-pipeline/actions/runs/39900277687).
`run.json` preserves authenticated terminal status and every step conclusion;
`hosted-run.log.gz` preserves the complete original job log. Raw pipeline JSON/MD
and component/strict logs are compressed to avoid lint self-scanning their quoted
code examples; `receipt.json` records stored and decompressed byte hashes.

Final host-engine identity was asserted after all composite setup: Eclipse
Adoptium Temurin17.0.10+7, Nextflow25.10.4, no parser override. The raw JVM output,
Nextflow version output and Java-executable SHA are retained. This is a host
engineering/runtime-setup receipt, not verification of R inside a container.

Actual counts:

| Check | Passed | Warnings | Failed | Other |
| --- | ---: | ---: | ---: | --- |
| Pipeline JSON |153|2|0|38ignored,1in-memory fixed|
| Pipeline CLI aggregate |195|2|0|Includes42local subworkflow passes|
| Seven local modules |245|28|0|Seven warnings in each of four groups|
| Two local subworkflows |42|0|0|No contributed nf-core components installed|
| Nextflow26.10.3 strict lint |23files without errors|7|0|Seven `when` deprecations|

The pipeline warnings are inherited hyphenated repository naming and native
input-directory MIME metadata. Module warnings are exactly seven `docker_tag`,
seven `singularity_tag`, seven `environment_yml_exists`, and seven
`when_condition`. The pipeline uses its shared exact-source image through runtime
profiles rather than static module container tags; public image distribution is
still pending separate approval. Conda is an unsupported/unqualified optional
runtime, not technically impossible. Required-stage guards intentionally fail
rather than permit selected work to be silently omitted. Strict `when`
deprecations retain the documented minimum/current compatibility boundary.
See [the applicability matrix](../../../../docs/nf-core-conformance.md) for named
external-project mappings, central recipe versus formal module-directory recipe
boundary, and remaining criteria. These warnings do not establish formal nf-core
admission or literal standalone-component specification conformance.

The one `rocrate_readme_sync` fixed item adds README description to an in-memory
RO-Crate descriptor; its implementation then detects equality and does not write
that descriptor in this case. Its raw fixed diagnostic is preserved. The
setup-nextflow installer also emits upstream Node `DEP0147` (`fs.rmdir` recursive)
deprecation text: direct action Node24/JVM corrections do not imply warning-free
upstream implementation.

The strict step's exact command is `NXF_VER=26.10.3 nextflow lint .` and its terminal
step conclusion is success. There is no separate26.10.3 engine-identity JSON in
this artifact: the explicit final engine assertion concerns25.10.4. Do not extend
it to numerical/current scientific-runtime qualification.

The local saved source snapshot was independently checked against every committed
production and qualification git blob at the exact tested head. It records
production`2a8b4a88ce8b2f653c7f9dee1ba246bd6a56c7bf69aa5b0433e3ad47cf90b40e`
and setup`b2a4142de18ef56890ed2995ad4036d03989654f48b51172f7a800ee1c268f20`.
This is committed-source reconstruction plus hosted checkout evidence, not a
hosted before/after source snapshot.

The paired scientific run39900277427 on this head was **CANCELLED**, as preserved
in its read-only terminal status JSON. It did not qualify science. This head also
predates the corrected three orchestration fixtures; subsequent full hosted
minimum/current tests remain a separate campaign. No R workflow, numerical
parity, nativeHDF5 CRT, positive Apptainer, Slurm, full-screen scale or registry
publication/pull pass follows from this engineering run.
