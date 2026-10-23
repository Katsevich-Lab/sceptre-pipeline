# Exact container payload audit and the unresolved authority gate

The [canonical payload manifest](../../../../docs/container-payload.md) describes the qualified f594 image, exact saved archive/artifact/run/admission identities, proposed destination and actual data/software included. [receipt.json](receipt.json) binds its SHA256 and this audit's scope.

This is a read-only source/context/config/log audit. No new image build, large image download, registry transfer, visibility action or indirect executor retry occurred. Automatic approval review blocked GHCR publication because trusted human approval for the payload, destination and public visibility was unclear; this is not a recorded human refusal. The coordinator owns any later approval question, after remaining source/CI work.

[evidence-manifest.json](evidence-manifest.json) hashes 27 compressed supporting files and their original bytes:

- `package-files.json.gz`: all 269 regular selected-archive member paths, byte sizes and SHA256s; 22 directories and no symlinks. The unchanged package archive is 3,311,229 bytes / f41a8fb7; its regular files total 5,537,149 bytes.
- `build-context-files.json.gz`: six allowlisted named inputs, reconstructed from exact f594 source and actual retained context metadata; per-file bytes/SHA256 and COPY destinations.
- `bundled-data-assets.json.gz`: all 26 selected RDA/extdata/RDS fixture assets with byte sizes/hashes, shapes where inspected and per-group license/provenance notices. The archive contains simulated examples, public annotations, regression fixtures and real Parse cell-line demo data; it is not data-free.
- `dataset-shapes.json.gz` and `inspection-methods.json.gz`: fresh-environment RDA metadata and Matrix Market header checks; no scientific analysis or arbitrary test-fixture execution.
- `installed-r-packages.tsv.gz`: actual image's 146 R-package name/version/build inventory. This is not a per-dependency data/license or whole-image filesystem SBOM.
- `source-notices/`: exact selected DESCRIPTION, data docs/generation recipes, reference-table provenance, Parse CC-BY-4.0 attribution, fixture README and checksums. Public source notices are copied; count matrices/RDA/RDS data are not duplicated here.
- `source-recipes/` and `qualified-context/`: exact f594 Docker/context/workflow source and reconstructed named nonarchive context files, separate from the qualified saved image bytes.
- `scope-and-authority.json.gz`, `context-scope-checks.json.gz` and `upstream-sources.json.gz`: specific automatic scope block, bounded credential/private-input checks and official source observations.

The [licensed-image qualification/admission receipt](../licensed-image-review/receipt.json) is unchanged. It preserves actual producer 39908971415 and strict Ubuntu origin/ZIP/archive/source/runtime/helper/loaded-image admission 39911817811. The full 611 MB GitHub artifact 12483325753 remains the concrete saved payload; this audit does not replace its checksums, expand qualification or authorize publication.
