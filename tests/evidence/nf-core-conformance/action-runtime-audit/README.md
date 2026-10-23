# Current direct-action and transitive runtime audit

Read-only upstream audit on2026-10-23; no workflow dispatch/registry operation
was performed from this audit worktree. Candidate commits5e0bf3e andca1035f were
prepared separately so the active local42-case source/oracle snapshot remained
unchanged. The lead owns publication and new hosted qualification.

Live official release tags were resolved through authenticated GitHub API to
immutable commits; action.yml and README were read at those commits.
`pins.json` records release URLs/tags/SHAs; `verified-pins.json` adds exact action
metadata hashes and runtimes. All five direct JavaScript actions use node24.
Setup-nextflow3.0.1 is composite; its sole nested action is setup-java at
1d018f9b8b9b505bb578a83b230fabcce01af93b, whose action.yml also uses node24.
Its installer runs bundled JavaScript from github.action_path; it no longer
checks out a mutable tagged helper repository into the workflow workspace.

Direct upgrades: checkout7.0.1,setup-java6.1.0,setup-python7.1.0,
upload-artifact7.0.2,download-artifact8.0.2,nf-core/setup-nextflow3.0.1.
Official tools4.2.0 generated template uses the same checkout7 and setup-nextflow3
pins, Python7 (older patch), uploader7 (mixed older/current patch) and downloader8
(older patch). The audit selects the live stable patches while retaining the
existing Python3.12.8, Nextflow25.10.4/26.10.3, scientific package and runtime data.
Uploader7 default archive=true and existing artifact path/name/retention/hidden-file
inputs are preserved; downloader8 is paired with it in the manual-only workflow.
Exact PR-head checkout, contents-read permissions and persist-credentials=false
are preserved. No pull_request_target or unsafe fork opt-in is introduced.

The previous setup-nextflow2 action used a nested checkout of mutable tagv2.1.4,
then setup-java with default distributionZulu and version17. Thus it could
replace the earlier directly requested Temurin17.0.10+7. The candidate explicitly
forwards both java-version17.0.10+7 and distributionTemurin into setup-nextflow3.
This aligns execution with the declared toolchain but is an actual JVM setup
change; previous hosted results are not claimed to qualify it. The lead is adding
after-setup JVM vendor/runtime and Nextflow-version readback/assertion before a
new corrected-head hosted run.

All direct actions are source-verified at their release pins. The remaining
upstream boundary is the pinned setup-nextflow3 composite implementation and its
pinned Node24 Java action, plus the supported GitHub-hosted runner environment;
there is no known residual nested Node20 action at the inspected pins. Actual
warning-free hosted execution remains to be verified on the new head.

The prospective manual registry image build also records OCI source and pipeline
revision labels before installed-package tests and artifact capture. Build/load
image-ID equality preserves those exact reviewed bytes through the later optional
push. Registry upload/public visibility/pull remain separately approval-gated;
none was executed here.

Full tools4.2.0 lint of the candidate: JSON153pipelinepass,CLI195aggregate including
42subworkflowpass;38ignored,1in-memory RO-Crate normalization,2knownwarnings,0fail.
Production identity remains2a8b4a88ce8b2f653c7f9dee1ba246bd6a56c7bf69aa5b0433e3ad47cf90b40e.
Candidate CI setup identitya9a5a276f9c98d4b8d847aeb9604c789c9b2d83b992bf30575632cce3e2bfdb9
precedes the lead's additional actual-JVM assertions and is not the final hosted
setup identity. Current local42-case qualification continues under its separately
recorded original setupc067146080f7ebf66f50546d80dd5072a7058af561e769113e9256cfa1584b6b.
