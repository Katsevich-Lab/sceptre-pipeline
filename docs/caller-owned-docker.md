# Caller-owned Docker preparation and output

The raw-JSON launcher, its Docker R helpers and the Docker workflow profile now
run as the invoking numeric UID and primary GID. Preparation and all scientific
tasks use writable container `HOME=/tmp` and `R_LIBS_USER=/nonexistent`, keeping
host/per-user R libraries out of the selected image runtime. The existing public
runtime/archive validation still runs. Repository and raw-data launcher mounts
remain read-only; the run directory remains writable. No package, statistical
method, RNG procedure, image builder or Apptainer execution/profile changed.

This follows the [documented Nextflow Docker runOptions pattern](https://docs.seqera.io/nextflow/reference/config).
The launcher additionally records its Docker UID/GID in its resume receipt.
Changing the caller or implementation cannot silently reuse an old unchanged
launcher request. Existing root-owned outputs are not recursively chowned or
rewritten; retain their evidence and use a fresh run directory with the corrected
source.

The mandatory launcher test checks raw, prepared, task-work and published trees
for caller UID, native-Linux primary GID and caller readability/writability. It
creates, edits and deletes a probe in every tree. All prepared seed/family/input
path mutation, raw-source and settings rejection checks remain active.
A separate real Docker named-volume test executes qualified R as UID1001/GID1002,
checks process IDs and on-disk inode ownership, and creates/edits/deletes its
prepared files. This proves native Linux ownership independently of Docker
Desktop bind projection. The temporary named volume is removed afterward.

Local corrected runs passed on both Nextflow25.10.4 and26.10.3: source-pinned raw
preparation, nativeHDF5 CRT discovery, exact public-R tables/fits/QC/design/
assignments/plans/RNG, unchanged cached science, and all mutation guards. Both
used selected LinuxARM64 imageb51c1cda and archivef41a8fb7. On this Darwin host,
Docker Desktop projected bind-mount GID0 rather than caller GID20; those receipts
explicitly record that limitation. Caller UID and edit/delete assertions remain
strict on Darwin, and native Linux host plus named-volume GID checks stay strict.
The initial overbroad Darwin GID assertion failures are preserved separately.

Source fix49adc15 has production identity985222799734e4a8a61473ade0753af9e06c450587f67623440ee447a723c61c.
Before/after production and qualification maps matched. Source code, actual
.command.run, ownership/Linux-UID receipts, original logs and negative guards
are retained under `tests/evidence/nf-core-conformance/caller-owned-docker`.
These bounded local runs do not replace required hosted AMD64 minimum/current
42-case qualification or new-source positive SIF execution. Those remain separate
receipts under the lead's final CI campaign; no new image build is implied by
this ownership-only source change.
