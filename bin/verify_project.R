#!/usr/bin/env Rscript
args <- commandArgs(TRUE)
script <- sub('^--file=', '', grep('^--file=', commandArgs(), value=TRUE)[1L])
helper <- dirname(normalizePath(script));source(file.path(helper,'pipeline.R'));source(file.path(helper,'project.R'))
if (length(args) != 1L) fail('Usage: verify_project.R PREPARED_DIRECTORY')
project_verify(args[1])
cat('PASS prepared project source/config/runtime/backing identity; unchanged resume admitted\n')
