#!/usr/bin/env Rscript
# Read-only topic provenance. No package analysis or RNG is invoked here.
args <- commandArgs(TRUE)
if (length(args) != 1L) stop('Usage: version-string.R ENVIRONMENT_LOCK')
cat(readRDS(args[[1L]])$version)
