#!/usr/bin/env Rscript
source('bin/pipeline.R'); source('bin/project.R'); source('tests/fixture.R')
a<-commandArgs(TRUE);root<-if(length(a)) a[1] else tempfile('checkpoint-');dir.create(root,recursive=TRUE)
f<-pipeline_fixture();lock<-package_identity();create_input(f$object,file.path(root,'input'),f$config,lock)
input<-file.path(root,'input')
for(stage in c('parameters','assignment','qc')) {output<-file.path(root,stage);run_stage(f$config,input,output,stage,271828L,identity=lock);input<-output}
state<-read_bundle(input,f$config,lock)
validate_checkpoint(state,'qc','discovery','analysis',271828L)
assert_error<-function(expr,pattern){e<-tryCatch(force(expr),error=identity);stopifnot(inherits(e,'error'),grepl(pattern,conditionMessage(e),fixed=TRUE))}
assert_error(validate_checkpoint(state,'assignment','discovery','analysis',271828L),'must match')
assert_error(validate_checkpoint(state,'qc','discovery','analysis',271829L),'RNG/seed')
assert_error(validate_checkpoint(state,'qc','discovery','assignment',271828L),'precedes')
run_stage(f$config,input,file.path(root,'discovery'),'discovery',271828L,identity=lock)
done<-read_bundle(file.path(root,'discovery'),f$config,lock)
assert_error(validate_checkpoint(done,'discovery','discovery','analysis',271828L),'already completed')
assert_error(validate_checkpoint(done,'discovery','calibration','analysis',271828L),'precedes a completed')
# Mutate backing object settings outside public API and rebind only container hash:
# package currentness must still reject, not trust pipeline completion flags.
stale<-state;stale$object@preparation@stages$cell_qc <- NULL
assert_error(validate_checkpoint(stale,'qc','discovery','analysis',271828L),'QC has not')
# All canonical stage subsets resolve same options without touching scientific RNG.
set.seed(333L);before<-.Random.seed
for(mask in 0:7) {selected<-c('calibration','power','discovery')[as.logical(intToBits(mask)[1:3])];s<-project_preflight(f$object,f$config,selected);stopifnot(identical(s$analyses,selected))}
stopifnot(identical(before,.Random.seed))
cat('PASS certified checkpoint currentness/seed/stage/family guards and every stage subset preflight; RNG preserved\n')
