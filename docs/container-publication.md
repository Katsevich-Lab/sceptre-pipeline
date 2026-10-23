# Exact-source containers and the separate registry decision

Build the bundled qualified package locally with one command:

```bash
bash container/build-bundled.sh
```

Use the emitted `sha256:…` image identity with the launcher and `-profile docker`.
`container/.build/bundled/source.json` records the exact package archive, source,
base image, R/Bioconductor and snapshot identities. Moving local tags are build
convenience only; scientific runs require the immutable image identity.

`publish-container.yml` separates image review from registry promotion. Its
read-only build runs only on pushes to `codex/container-review-*` that change
that workflow or its two artifact-admission helpers. There is no PR, tag, release
or scheduled trigger. Documentation/evidence-only pushes do not rebuild the
reviewed image. The ordinary scientific CI workflow and its required tests are
unchanged by this isolated route.

The review job checks out and labels the actual source commit, builds LinuxAMD64,
then uses that immutable image ID for installed-package checks and real bounded
nativeHDF5 CRT/public-R all-family, checkpoint, unchanged-resume and source guards.
Only after success does it save the image archive, record its SHA256 and upload
an immutable run/attempt-named Actions artifact with14-day retention. This is
artifact storage, not GHCR publication. Source, JVM, image, package-test and
scientific receipts travel with it. The helpers have separate SHA256 identities
because the existing source-snapshot qualification map excludes `.github/scripts`.
No ARM64 or multiarchitecture qualification follows from this AMD64 route.

On a later approved manual promotion, `approve_publication=true` skips the build
job entirely. It must name the originating successful review run and artifact ID,
exact source commit, immutable image ID and saved archive SHA256. The promotion
verifies GitHub workflow/run/latest-attempt/artifact membership and server digest,
downloads that single artifact, checks its source/runtime/scientific/helper and
archive identities, then checks the loaded image ID, LinuxAMD64 and OCI labels
before login and push. It never rebuilds or resaves the image after approval.
Only this explicit manual job requests `packages: write`; build permissions are
`contents: read`. The `container-publication` reviewer environment is a proposed
project safeguard; destination-specific authorization is still pending.

The dedicated branch atc13e94da0b8e9a54a2dd2460ad8514d04bd0fee0 was pushed by the
lead under the existing source/CI authorization. Its actual push run
[39904756647](https://github.com/Katsevich-Lab/sceptre-pipeline/actions/runs/39904756647)
started; the preserved snapshot is **in progress**, with publication skipped.
The13offline unit methods and static/independent source reviews passed; they do
not qualify the rebuilt image. See
`tests/evidence/nf-core-conformance/image-review-proposal` for exact bytes and
boundaries. Production475e4199 and selected archivef41a8fb7 are unchanged.

The repository default is `main` at unchanged `5cc91e51`; its workflow-directory
read returned404. The [GitHub manual-run documentation](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow)
describes default-branch registration. Our observed registered-workflow API route
is narrower evidence: `gh workflow run linting.yml --ref
codex/static-review-parity-20261023` successfully dispatched and completed
[39906655219](https://github.com/Katsevich-Lab/sceptre-pipeline/actions/runs/39906655219)
at exact `9aa9dfd`, without any default-branch source write. The intended later
publisher route is likewise an API dispatch of the registered publisher workflow
on an exact reviewed ref. Publisher dispatch remains untested: publication is
not authorized, and a false dispatch would rebuild an already running image.
No default-branch admission is currently proposed. If an authorized promotion
is rejected by the API, preserve the precise error before proposing any source
registration change. No registry or visibility operation has occurred.

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
