# Exact-image review and promotion proposal evidence

Reviewed source commitc13e94da0b8e9a54a2dd2460ad8514d04bd0fee0 on the isolated
codex/container-review-science-20261023 branch, based onbfdfe70 through1373c2d.
Publisher SHA2569c504e1825d8bee74ce5254ec11709bcf3737eb68dd331033a4fbd59e699050b;
helper2d642b58066a52a0b62ecc2b078d39249f7748b1dcbe598ec9a4fce5fa463475;
unit helper e15571cdf0c62a3fb21e40a0c68f64464f6b1db9adf91a2f2f7ead1ad50bb22a.
Compressed exact originals are retained. Production475e is unchanged;
qualificatione9757ab9 covers the workflow but excludes the two new helpers,
whose hashes and exact gitcommit bind them separately. No classifier or nf-test
workflow change was retained.

Thirteen offline unit methods with negative subcases passed, covering origin
repository/workflow/run/source/event/branch/status/job/attempt/artifact/digest,
input injection, archive corruption/checksum path, receipt/helper/gates/source,
loaded imageID/platform/labels and runtime rejection. These fixtures contain no
real Docker image and do not establish scientific execution. Actionlint1.7.12
passed with no diagnostics; unavailable ShellCheck was explicitly disabled.
YAML1.2,9bash-n checks, embedded Python compilation and permission/event/
science-before-archive/strict promotion/no-rebuild structural checks passed.
Independent source/fixture review by hosted_ci_preflight passed the exact hashes.

The lead pushed this source branch under existing source/CI authorization. Actual
push run39904756647 was **in progress** at the retained authenticated API snapshot;
its publish-approved-amd64 job was **skipped**. No qualified image/archive SHA or
artifact ID is asserted yet. Completion, exact artifact identity and numerical
results require a later terminal receipt. The push neither changes PR1's head nor
cancels its existing scientific campaign. This child performed no push, dispatch,
image build, artifact upload or registry operation.

The source job has only contents:read and validates the exact immutable AMD64
image before archive save/upload. Later true manual promotion names the already
successful originating artifact and expected source/image/archive identities;
it has no build dependency and no rebuilding step. Publication/public visibility
and anonymous digest pull remain separate pending authorization/execution.

Repository metadata originally usedcodex/native-schema7-hosted-ci as default;
root later changed the default metadata to main without source admission. Raw
before/after API reads are retained. Main workflow-directory GET returned404.
Dedicated push execution works without manual registration; future manual
workflow_dispatch still requires the workflow on the default branch under the
[official requirement](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow).

artifact-hashes.json binds retained original files; README and the hash index are
metadata. Older FINAL-README.md/final-receipt.json describe the child handoff
before the lead started the actual build; actual-build-started.json is the later
source of truth for the in-progress execution state. No success is inferred from
that initial snapshot or from static/fixture checks.
