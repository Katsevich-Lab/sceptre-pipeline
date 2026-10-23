# Exact-source containers and the separate registry decision

Build the bundled qualified package locally with one command:

```bash
bash container/build-bundled.sh
```

Use the emitted `sha256:…` image identity with the launcher and `-profile docker`.
`container/.build/bundled/source.json` records the exact package archive, source,
base image, R/Bioconductor and snapshot identities. Moving local tags are build
convenience only; scientific runs require the immutable image identity.

The manual `publish-container.yml` workflow is a reviewable proposal. It has no
push, PR, tag, release or scheduled trigger. Its default dispatch builds and runs
the installed-package checks without upload. The optional publication job requires
an explicit boolean approval and the `container-publication` GitHub environment.
The required-reviewer environment is a proposed project safeguard, not an
externally imposed approval rule. Destination-specific authorization for
`ghcr.io/katsevich-lab/sceptre-pipeline` is still pending; after that authorization,
we can configure and read back the environment within the approved scope without
asking for the same destination permission twice. Only this
job requests `packages: write`; all other jobs retain read-only permissions.

The proposed job uploads the tested AMD64 image under a run-unique source/architecture
tag, records its content digest, and pulls that digest back. It preserves source,
image and package-test receipts. It does not claim ARM64 or multiarchitecture
support from an AMD64 build. Additional architecture images require their own
execution qualification before an OCI index can be published.

**Publication and public pull validation are pending approval and execution.**
GHCR package visibility is a separate owner-controlled action; this workflow does
not change it. After approved publication, the owner must explicitly set the
approved public visibility if intended and verify an unauthenticated digest pull
in a fresh environment. An authenticated same-job pull alone is not that proof.
No remote digest may be inserted into defaults or described as pullable before
that receipt exists. The local exact-source build remains the supported path.

The positive Apptainer CI job converts its locally built Docker daemon image to
SIF without registry upload, records the SIF checksum, and executes both native
HDF5 CRT/checkpoint/resume and the single-command raw-input launcher. Execution
uses `--containall --cleanenv` with explicit task/source/input binds, preventing
host home R libraries from replacing the qualified package. CI configuration is
not a successful SIF execution receipt; see the conformance ledger for actual runs.
