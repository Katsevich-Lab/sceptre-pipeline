# Tracked and external configuration closure regression

Production fix03b3974 and mandatory CI regressionf757105. This supersedes the
previous implementation's provenance boundary: it skipped tracked roots and
could miss external includes below tracked files. Earlier production2a8b4a88
receipts remain historical; they do not qualify this fix.

Both final supported-default campaigns are terminal **PASS**, exit0:
Nextflow25.10.4 and26.10.3, each13actual Nextflow invocations. Each runs two real
native R-backed parameters workflows, checks the exact external digest list,
checks unchanged resume and cached scientific work, then changes only the
external leaf and requires rejection with every certified published byte
unchanged. Both chains are exercised: tracked root→tracked config→external leaf,
and external root→tracked bridge→external leaf. The tracked include has a
trailing comment followed by an ordinary statement. Existing inline profile
blocks are traversed. Comment and quoted `includeConfig` text is ignored.

Each campaign also rejects seven unsupported expressions before any submitted
scientific task, signature or parameters publication: variable path, direct
concatenation, comment-separated concatenation, comment-separated repetition,
comment-separated method call, multiline concatenation and a hidden include in
string interpolation. Under25.10.4 all reach the pipeline identity guard. Under
26.10.3, comment-separated and multiline '+' expressions and the hidden call
are rejected earlier by the native strict parser; exact native diagnostic
whitelists are narrow and recorded as `matched_rejection`. Other four current
cases reach the identity guard. A nonzero exit alone never satisfies the test.

Pristine pipeline source under test:
production`475e419938a86aa9aa19060730299c2276ab3500483e3bdd9e493c7a9c2f5913`,
qualification`9aef27aa5d954f50bc2f069b7de9fc5867b1ce7cac6be8a1ee5758206f83f798`.
Before/after maps match; the committed-source snapshot identifiesf757105.
Every generated project main.nf was separately verified byte-identical to the
final main.nf. Test projects deliberately inject tracked/external config
includes, so their config files differ from pristine production by design.
Those exact generated config snippets and saved signatures are preserved.
Only synthetic data were used; no external credentials/configs were copied.

Exact floor scientific container:
`sha256:b51c1cdaef908f6386b3313bd787f5d46dcc7b3f08c5fe28b271d2e5c85cd6c9`.
The selected scientific archive remainsf41a8fb7, schema7. Both final host-engine
receipts verify Temurin17.0.10+7 and the respective exact Nextflow release,
without parser overrides. These are bounded config-admission/resume checks,
not full HDF5 CRT/all-family numerical, Apptainer, scheduler or scale qualification.
The lead performs those broader science checks separately on the new source.

Latest full nf-core4.2 pipeline lint on these source/helper bytes:153JSONpasses,
195CLIaggregate passes,38ignored,1in-memory RO-Crate fixed item,2documented
warnings,0failures. Strict26.10.3:23files without errors,7known when-deprecation
warnings. Reused component checks245/28/0 modules and42/0/0 subworkflows have
byte-identical component sources; their original raw logs are preserved.
No warnings were disabled to accept this patch.

The exploratory-harness/ directory preserves initial empty-CLI/schema and native
parser diagnostic assertion failures, plus explicit exit143 interruptions while
required expression coverage was being finalized. They are not qualification.
The earlier successful minimum campaign is also retained separately. Current
negative preprobes establish the exact native-versus-pipeline rejection boundary
before the final full campaigns. Compressed originals avoid teaching source
lint to execute/scan negative examples. artifact-hashes.json binds every raw
artifact's stored and decompressed bytes; README and this hash index are metadata.
