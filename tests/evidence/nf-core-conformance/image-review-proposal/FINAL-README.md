# Dedicated review build and later exact-artifact promotion

Final reviewed commit c13e94da0b8e9a54a2dd2460ad8514d04bd0fee0 on
codex/container-review-science-20261023, based on bfdfe70 through1373c2d.
No nf-test.yml edit or classifier was retained. No PR is needed for this branch.
Root authorized the lead to push the isolated source branch and start its one
read-only dedicated build while existing PR science CI continues unchanged.
This child has not pushed, dispatched, built an image, uploaded or published.

The final workflow has only dedicated push and manual dispatch triggers. Pushes
match codex/container-review-* and precisely the publisher workflow +two owned
helpers. Actual per-push path filtering prevents documentation/evidence-only
commits from rebuilding the reviewed image. Manual true promotion skips build;
optional false manual builds require the dedicated review branch.

The build qualifies the actual immutable AMD64 image, saves its exact archive
only after successful installed-package/nativeHDF5/publicR/all-family/checkpoint/
resume/source checks, records actual gitHEAD (not PR merge SHA), imageID and
archiveSHA, explicit helperSHA map and source/JVM/runtime/science receipts. The
immutable Actions artifact has run+attempt name and14-day retention. Its actual
ID and checksum must be known before the final GHCR approval.

A later true manual dispatch must name the exact successful origin run/artifact,
approved sourceSHA/imageID/archiveSHA. Read-only REST validates repository,
workflow path+ID, source, event/review branch, unique successful latest-attempt
build-review job, artifact membership/name/expiry/serverdigest. Download is by
single artifactID with digest mismatch fatal. Local admission checks archiveSHA,
all source/runtime/science receipts and explicit helperSHA fetched at the approved
source; Docker load is followed by imageID/LinuxAMD64/OCI source checks before
login/tag/push. No new image build/save occurs in promotion.

Independent source+offline review passed. Thirteen offline unit methods (many
negative subcases), actionlint1.7.12, YAML1.2, all9embedded shell syntax checks and
embedded Python compilation/structural ordering/permissions/no-rebuild checks
passed. ShellCheck is unavailable; actionlint integration was explicitly disabled.
These are guard/static receipts, NOT actual AMD64/scientific execution evidence.
Production475e is unchanged; source-snapshot qualification identity excludes
.github/scripts, so the separate helper hashes and exact commit must be retained.

Root subsequently changed repository default metadata to main; no default source
admission was made. The main workflow-directory contents request returned HTTP404, so that branch
has no registered workflow source at this path.
The earlier repository.json records the prior default metadata and the new
repository-after-default-metadata.json records main. A push event on the dedicated
branch can run without default registration, but manual workflow_dispatch still
requires the workflow on the default branch:
https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow

A future registration/source-admission or authorized local promotion route is
separate. No default-branch/settings/merge/visibility/registry operation was
performed by this child. An authenticated pull after approved push does not prove
anonymous/public package visibility; visibility has not been changed by proposal.
