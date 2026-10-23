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
that workflow, its two artifact-admission helpers or the central Dockerfile. There is no PR, tag, release
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

The metadata-corrected review source is `f59434dccc8bfe2eed2b087d49fb72f21944607a`.
[Producer39908971415](https://github.com/Katsevich-Lab/sceptre-pipeline/actions/runs/39908971415)
and [strict Ubuntu admission39911817811](https://github.com/Katsevich-Lab/sceptre-pipeline/actions/runs/39911817811)
are **terminal SUCCESS**; publication was skipped. They bind the saved image
`sha256:36979a6a70b182e27e2e6918f54cfd8482821291fe5b007aed7b481855c771ae`
and archive SHA256 `9ebecf49d5576d52077035ad72d7e7128a62d1fd72bdb821eceba599f5e3e403`.
Actual artifact12483325753 ZIP SHA256 is
`a3aba8d1238caf3c06c97e0370e335ed67b4f296644f443acaf19d9efccfa8ad`.
The admission downloaded and verified these bytes, then loaded and checked the
exact original image ID/platform/labels; it did not rebuild. Production98522279
and selected archivef41a8fb7 remain unchanged. Recipe/setup3106d65d and admission0dcb
have separate source identities. Fifteen offline methods passed. [Raw evidence](../tests/evidence/nf-core-conformance/licensed-image-review/receipt.json)
and the [complete concrete payload](container-payload.md) preserve the details.
The final integrated PR's complete checks separately qualify later demo/test fixes.

The recipe explicitly records the SCEPTRE project's `GPL-3.0-only` label, matching
the selected package's `License: GPL-3`, and names the project vendor/contributor
source. Scoped Rocker base attribution and the exact immediate pinned base
name/digest remain separate. Dependencies retain their respective licenses; this
metadata correction does not relicense them. Both floor and current generated
profiles bind their actual immediate base. Programmatic comparison verified that
nonmetadata Docker instructions, package source/archive and dependency-install
bytes were unchanged by this correction. The build and archive/load admission
checks now reject inherited base license/vendor labels as project metadata.

The earlier sourcec13 image run39904756647 and actual no-rebuild Ubuntu admission
39908251912 both **passed**. That image is historical because it retained the
base's `GPL-2.0-or-later` application label. Its saved archive/config identity is
not transferred to the metadata-corrected image. [Preserved receipts](../tests/evidence/nf-core-conformance/reviewed-image-c13/receipt.json)
include the original producer-schema helper failure, the correction, and real
API/download/checksum/source/loaded checks. On macOS Docker Desktop's containerd
store, the same archive loads by OCI manifest identity while the Linux classic
Docker image ID is its config digest; the strict Mac loaded-ID check rejected.
The recorded manifest-to-config link is additional evidence, not a waiver or a
cross-engine loaded PASS. Actual hosted Ubuntu strict loading passed for that
historical archive; the corrected archive has its own successful strict Ubuntu admission above.

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
The present gate is an actual automatic-review rejection: the prior trusted
human approval was judged insufficiently specific for this container payload,
GHCR destination and public visibility. Earlier destination-gating language
started as our scope interpretation; it was not an explicit human prohibition.
The concrete tested payload and operations are being prepared for a specific
review decision after source/CI qualification. No indirect executor retry is
authorized by this document.

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
