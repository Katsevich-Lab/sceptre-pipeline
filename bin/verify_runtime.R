#!/usr/bin/env Rscript
# Runtime receipt check before any project import. No inference is performed.
args <- commandArgs(TRUE)
if (length(args) != 1L) stop('Usage: verify_runtime.R PIPELINE_SOURCE_JSON')
expected <- jsonlite::read_json(args[1])
path <- '/opt/sceptre/source.json'
if (!file.exists(path)) stop('Container lacks /opt/sceptre/source.json; build it from this pipeline exact-source recipe.')
actual <- jsonlite::read_json(path)
if (!identical(expected$archive_sha256,actual$sceptre_archive_sha256) ||
    !identical(expected$source_commit,actual$sceptre_commit) || !identical(actual$object_schema,7L))
    stop('Container source/archive/schema differs from the selected pipeline package.')
if (!requireNamespace('sceptre',quietly=TRUE)) stop('Container lacks the selected installed package.')
cat('PASS container selected source/archive/schema receipt\n')
