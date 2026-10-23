#!/usr/bin/env Rscript
source('bin/pipeline.R')
a<-commandArgs(TRUE);stopifnot(length(a)==3L)
config<-readRDS(file.path(a[1],'analysis_config.rds'));lock<-readRDS(file.path(a[1],'environment_lock.rds'));backing<-file.path(a[1],'backing')
x<-read_bundle(file.path(a[2],'discovery','state'),config,lock,backing)
y<-read_bundle(file.path(a[3],'discovery','state'),config,lock,backing)
stopifnot(identical(sceptre::get_result(x$object,'run_discovery_analysis'),sceptre::get_result(y$object,'run_discovery_analysis')),
 identical(x$manifest$rng_state,y$manifest$rng_state),identical(x$manifest$rng_kind,y$manifest$rng_kind),
 identical(x$object@fits,y$object@fits),identical(x$object@preparation@analysis_cells,y$object@preparation@analysis_cells),
 !dir.exists(file.path(a[3],'parameters')),!dir.exists(file.path(a[3],'assignment')),!dir.exists(file.path(a[3],'qc')),
 !dir.exists(file.path(a[3],'calibration')),!dir.exists(file.path(a[3],'power')))
source(file.path(a[3],'exports','scientific-report','reopen_export.R'))
portable<-reopen_sceptre_export(file.path(a[3],'exports','scientific-report'))
stopifnot(identical(sceptre::get_result(portable,'run_discovery_analysis'),sceptre::get_result(y$object,'run_discovery_analysis')))
cat('PASS actual Nextflow native HDF5 CRT current power-checkpoint continuation equals uninterrupted public R; fits/result/RNG unchanged; skipped stages absent and portable output reopens\n')
