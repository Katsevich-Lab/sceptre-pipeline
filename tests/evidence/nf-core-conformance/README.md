# Local external nf-core engineering evidence

This directory records actual local checks against tools4.2.0, nf-test0.9.5,
minimum25.10.4 default/current26.10.3 strict parsing and the selected archive
f41a8fb7. `tooling.json` records the exact cached official module-schema source.
`source-before.json` separately binds production and qualification/oracle bytes;
the lead and conformance worktrees matched both before the campaign.

Pipeline lint:195pass,0fail,2warnings,38ignored diagnostics. Local modules:
245pass,0fail,28warnings. Local subworkflows:42pass,0warnings,0fail. Strict current
Nextflow lint:0errors,7when-deprecation warnings. Full raw logs and named external
mappings stay visible. See docs/nf-core-conformance.md for residual boundaries;
these are not formal nf-core organisation or standalone component admission.

Both supported-default bounded suites are terminalPASS: minimum25.10.4 3/3,
current26.10.3 3/3, zero skips and unchanged production/oracle identities.
Their TAP/XML/logs and before/after snapshots are in bounded-minimum/ and
bounded-current/. The full42-case minimum suite remains in progress; its terminal
receipt will be added separately. Earlier
exploratory campaigns were deliberately interrupted for source/parser/naming
fixes, not qualified. The profile-only harness failure during that work was fixed
by importing the real runtime profiles into the test wrapper configuration.

No registry upload, public digest pull, positive Apptainer, full-screen scale,
current-source Slurm or hosted CI success is asserted by local configuration/lint.
The positive SIF job and approval-only container workflow are prepared separately.
Only synthetic fixtures are used; no real-screen or participant data are present.

The complete lint JSON/Markdown are archived as deterministic `.gz` files, with
exact decompressed SHA256 in `archived-reports.json`. This preserves raw bytes:
`gzip -dc pipeline-lint.json.gz` reads the original. Tools scans arbitrary
repository text and otherwise diagnoses its own quoted passed-check messages as
source matches; archiving report data avoids that self-reference without any
workflow/lint exclusion. Runtime/oracle files remain fully inspected.
