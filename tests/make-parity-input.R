#!/usr/bin/env Rscript
source('bin/pipeline.R');source('bin/project.R');source('tests/fixture.R')
a<-commandArgs(TRUE);stopifnot(length(a)==1L);root<-a[1];dir.create(root,recursive=TRUE)
f<-pipeline_fixture(moi='high',control='complement',mechanism='crt')
sce<-sceptre::get_screen_experiment(f$object)
meta<-as.data.frame(SummarizedExperiment::rowData(SingleCellExperiment::altExp(sce,'gRNA')));meta$grna_id<-rownames(sceptre::get_grna_matrix(f$object))
project_prepare(list(method='matrix',analyses=c('calibration','power','discovery'),seed=271828,
 arguments=list(response_matrix=sceptre::get_response_matrix(f$object),grna_matrix=sceptre::get_grna_matrix(f$object),
 grna_target_data_frame=meta,moi='high',extra_covariates=sceptre::get_cell_covariates(f$object)[,c('batch','z'),drop=FALSE],use_hdf5=TRUE)),f$config,file.path(root,'prepared'))
file.copy(file.path(root,'prepared','analysis_config.rds'),file.path(root,'prepared','config.rds'))
file.copy(file.path(root,'prepared','environment_lock.rds'),file.path(root,'prepared','lock.rds'))
