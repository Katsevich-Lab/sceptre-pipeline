#!/usr/bin/env Rscript
# Assert the actual Nextflow preflight envelope describes its scientific object.
source('bin/pipeline.R')
a<-commandArgs(TRUE);stopifnot(length(a)==3L)
config<-readRDS(file.path(a[1],'analysis_config.rds'));lock<-readRDS(file.path(a[1],'environment_lock.rds'))
for (i in 2:3) {
 state<-read_bundle(file.path(a[i],'discovery','state'),config,lock,file.path(a[1],'backing'))
 json<-jsonlite::read_json(file.path(a[i],'resolved_settings.json'),simplifyVector=TRUE)
 spec<-state$object@spec
 stopifnot(identical(json$config_sha256,hash_value(config)),
  identical(json$resolved$control_group,if(spec@control_group_complement) 'complement' else 'nt_cells'),
  identical(json$resolved$resampling_mechanism,if(spec@run_permutations) 'permutations' else 'crt'),
  identical(json$resolved$resampling_approximation,spec@resampling_approximation),
  identical(json$resolved$grna_integration_strategy,spec@grna_integration_strategy),
  identical(json$resolved$multiple_testing_alpha,spec@multiple_testing_alpha),
  identical(json$resolved$multiple_testing_method,spec@multiple_testing_method),
  identical(json$resolved$design,hash_value(state$object@preparation@design_matrix)),
  json$requested$analysis$discovery_pairs$rows==nrow(config$analysis$discovery_pairs))
 expected<-if(i==2L) c('calibration','power','discovery') else 'discovery'
 stopifnot(identical(json$analyses,expected))
}
cat('PASS actual Nextflow requested/resolved control/method/approximation/integration/alpha/correction/design/config/family envelopes match complete scientific state and checkpoint stage selections\n')
