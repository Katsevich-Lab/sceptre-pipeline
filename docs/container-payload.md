# Exact container payload for a later publication decision

Status: **automatic approval review blocked registry publication**. The coordinator reports that trusted human approval was not clear for the container payload, GHCR destination and public visibility. This is a scope/authority gate, not a recorded human refusal. No registry upload, visibility change or indirect publication retry is authorized by this audit. Existing source/CI work continues. This document prepares a concrete payload; it does not request publication now.

## Exact saved asset

| Field | Qualified identity |
|---|---|
| Image source | [`f59434dccc8bfe2eed2b087d49fb72f21944607a`](https://github.com/Katsevich-Lab/sceptre-pipeline/tree/f59434dccc8bfe2eed2b087d49fb72f21944607a) |
| Selected SCEPTRE archive | `f41a8fb7e1bc10366e8efcc7a31644d4c8356bc4eca8adda9ca949c951de4fb4`, 3,311,229 bytes; package 0.99.0 / schema 7 |
| Immutable AMD64 image | `sha256:36979a6a70b182e27e2e6918f54cfd8482821291fe5b007aed7b481855c771ae` |
| Saved image archive SHA256 | `9ebecf49d5576d52077035ad72d7e7128a62d1fd72bdb821eceba599f5e3e403` |
| GitHub artifact | `12483325753`, 611,265,493 bytes; ZIP SHA256 `a3aba8d1238caf3c06c97e0370e335ed67b4f296644f443acaf19d9efccfa8ad`; expires 2026-11-06T06:27:47Z |
| Producer | [39908971415](https://github.com/Katsevich-Lab/sceptre-pipeline/actions/runs/39908971415), success; publication skipped |
| Exact-byte Ubuntu admission | [39911817811](https://github.com/Katsevich-Lab/sceptre-pipeline/actions/runs/39911817811), success; origin/ZIP/archive/source/helper/runtime and loaded image identity checked |
| Proposed destination, not published | `ghcr.io/katsevich-lab/sceptre-pipeline:source-f59434dccc8bfe2eed2b087d49fb72f21944607a-amd64-review-39908971415-12483325753` |

Any later cleared scope would promote precisely this saved archive without rebuilding, then handle the explicitly approved package visibility and an unauthenticated digest pull. There is no published GHCR digest to claim yet. The recorded image size is 1,603,164,644 bytes; this Docker metadata figure differs from compressed archive/ZIP sizes.

## Build-context and installed-source boundary

The [exact Docker recipe](https://github.com/Katsevich-Lab/sceptre-pipeline/blob/f59434dccc8bfe2eed2b087d49fb72f21944607a/container/Dockerfile) uses pinned Rocker R 4.5.1 / Bioconductor 3.22 and a named generated context. The context contains only `.dockerignore` (82 bytes), `Dockerfile` (2,922), `install-dependencies.R` (1,635), `source.json` (539), `source.sha256` (81), and `sceptre.tar.gz` (3,311,229). Context-file SHA256s are recorded in the accompanying audit JSON. This is reconstructed deterministically from exact f594 source and the actual retained context/source.json, not a new image build.

COPY places only the archive, source JSON/checksum and dependency installer in `/opt/sceptre`. The archive is extracted under `/opt/sceptre/package` for `R CMD INSTALL`, and that temporary extracted tree is removed in the same RUN. The original complete source archive remains at `/opt/sceptre/sceptre.tar.gz`; installed package code, data, scripts and documentation reside in the R library. Its 269 regular source files total 5,537,149 uncompressed bytes; all paths/sizes/hashes are inventoried. Historical test fixtures remain inside the source archive even though the installation command does not request separately installing tests.

The image also contains the OS/R compiler/runtime and 146 recorded R packages with their own software, examples/data and licenses. This audit inventories the selected SCEPTRE archive completely; it is not a per-dependency data/SBOM or whole 1.6 GB filesystem audit.

## Bundled data and examples

| Actual archive content | Size and meaning | Recorded license/provenance |
|---|---|---|
| `data/gene_position_data_frame_grch37.rda`; `...grch38.rda` | 599,797 and 371,806 bytes; 57,773×4 and 36,572×4 public reference-coordinate tables | Archive source documents 10x/Ensembl references. Package declares GPL-3; no separate data-specific license notice is bundled for these derived tables. No independent relicense of upstream annotations is asserted. |
| `data/highmoi_example_data.rda`; `lowmoi_example_data.rda`; `grna_target_data_frame_highmoi.rda` | 30,750; 45,976; 1,106 bytes. Simulated high-MOI 100 genes / 60 guides / 500 cells, low-MOI 100 genes / 50 guides / 1,000 cells, 60×5 guide annotation | Package GPL-3; data documentation explicitly calls the expression examples simulated, modeled on Gasperini/Papalexi; gene identifiers/coordinates draw on public annotations. |
| `inst/extdata/highmoi_example/gem_group_{1,2}` | Six gzipped feature/barcode/matrix files total 89,445 bytes; simulated combined 160-feature matrices for 242 and 258 cells | Derived from the bundled high-MOI simulation; package GPL-3, no separate data notice. |
| `inst/extdata/parse_example` | Five files total 272,373 bytes, including attribution README. Actual public cell-line demo subset: 5,000 cells × 266 genes and 5,000 × 3 guides; not simulated | **CC BY 4.0**, attributed to Parse Biosciences in README, source generator and importer docs; [original dataset](https://www.parsebiosciences.com/datasets/technical-performance-of-crispr-detect-in-cell-lines/) independently confirms this license and cell-line source. |
| `tests/testthat/fixtures/**/*.rds` | Ten serialized regression/historical-format inputs total 231,606 bytes | Package GPL-3; archive README describes synthetic counts/configurations, constructed sampler inputs and toy historical saved objects. These serialized files are part of the payload. |
| Documentation/examples/generators | 43 Rd files with 36 example blocks; compiled vignette/source/script; simulator/data-generation scripts and a pipeline PNG | Package GPL-3 except specifically attributed embedded data, notably Parse CC-BY-4.0. Complete file inventory includes their actual sizes. |

Per-file data/example inventory records 26 data/example assets, dimensions where read, byte sizes, hashes and source-notice classifications. The package contains no full FASTQ/BAM/CRAM, reference FASTA/GTF or user run bundle; the complete 269-file inventory is authoritative for this narrower archive statement. Reference tables have documented public provenance, not an independently established all-assets SPDX grant. [GENCODE](https://www.gencodegenes.org/pages/data_access.html) describes its upstream annotations as open-access; this does not replace the archive-specific provenance boundary.

## Private-input and credential-injection check

The generated allowlist excludes the checkout, user home, project inputs/outputs, run directories and CI working state. There is no Dockerfile COPY of those paths, no secret/SSH mount or credential build argument in the qualified build command, and actual Config.Env contains only the recorded runtime/build settings. No common credential-file names were present in the selected 269-file archive. Historical developer paths and author/contact text inside source scripts are text in the already-selected package; those referenced host files/directories were not included by context generation.

Scientific CI creates/mounts synthetic test data after the image build and saves the original immutable image ID; it does not commit test containers into the image. These source/context/config/log checks support that no additional unrequested private project dataset or credential was injected by this build. They do not claim a forensic scan of every inherited OS/dependency byte, nor that the image contains literally no data.

The project OCI `GPL-3.0-only` label describes SCEPTRE/project software; it does not overwrite Parse CC-BY-4.0 or independent base/dependency licenses. The automatic scope block remains in force. No publication question or transfer is performed by this manifest.

The [machine-readable audit and raw source notices](../tests/evidence/nf-core-conformance/container-payload-audit/README.md) bind the complete file inventory, shapes, context hashes, scope checks and exact supporting source bytes. The [qualified-image receipt](../tests/evidence/nf-core-conformance/licensed-image-review/receipt.json) remains unchanged.
