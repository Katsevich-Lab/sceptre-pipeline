#!/usr/bin/env Rscript
source('bin/pipeline.R'); source('bin/project.R')
args <- commandArgs(TRUE); root <- if(length(args)) args[1] else tempfile('raw-project-');dir.create(root,recursive=TRUE)
assert_error <- function(expr, pattern) { e<-tryCatch(force(expr),error=identity);stopifnot(inherits(e,'error'),grepl(pattern,conditionMessage(e),fixed=TRUE)) }
raw <- file.path(root,'raw');dir.create(raw)
writeLines(c('g1\tMT-one\tGene Expression','guide1\tGuide1\tCRISPR Guide Capture','g2\tGene2\tGene Expression','guide2\tGuide2\tCRISPR Guide Capture'),file.path(raw,'features.tsv'))
writeLines(c('a','b','c'),file.path(raw,'barcodes.tsv'))
writeLines(c('%%MatrixMarket matrix coordinate integer general','4 3 7','1 1 2','1 2 1','2 1 5','2 3 1','3 2 4','4 1 1','4 2 3'),file.path(raw,'matrix.mtx'))
meta <- data.frame(grna_id=c('guide1','guide2'),grna_target=c('non-targeting','target'),chr=c('chr1','chr1'),start=c(10,20),end=c(11,21))
config <- list(analysis=list(formula_object=~1),assignment=list(method='maximum'))
for (method in c('tenx','cellranger')) {
 for (backed in if(method=='cellranger') c(FALSE,TRUE) else TRUE) {
  a <- list(moi='low',grna_target_data_frame=meta)
  a[[if(method=='tenx') 'samples' else 'directories']] <- rep(raw,2)
  if (method=='cellranger') a$use_hdf5<-backed
  name <- paste0(method,'-',backed); dest<-file.path(root,name)
  project_prepare(list(method=method,arguments=a,analyses=character()),config,dest)
  project_verify(dest)
  directa<-a;directa$directory_to_write<-file.path(root,paste0(name,'-direct'))
  direct <- do.call(if(method=='tenx') sceptre::import_data_from_10x else sceptre::import_data_from_cellranger,directa)
  object <- read_bundle(file.path(dest,'input'),config,readRDS(file.path(dest,'environment_lock.rds')),file.path(dest,'backing'))$object
  stopifnot(identical(as.matrix(sceptre::get_response_matrix(object)),as.matrix(sceptre::get_response_matrix(direct))),identical(as.matrix(sceptre::get_grna_matrix(object)),as.matrix(sceptre::get_grna_matrix(direct))),identical(sceptre::get_cell_covariates(object),sceptre::get_cell_covariates(direct)))
 }
}
# Parse public API consumes cell-by-feature MatrixMarket and feature CSVs.
gene<-file.path(raw,'gene.mtx'); guide<-file.path(raw,'guide.mtx')
writeLines(c('%%MatrixMarket matrix coordinate integer general','3 2 3','1 1 2','2 2 4','3 1 1'),gene)
writeLines(c('%%MatrixMarket matrix coordinate integer general','3 2 3','1 1 5','2 2 3','3 1 1'),guide)
genef<-file.path(raw,'genes.csv');guidef<-file.path(raw,'guides.csv')
writeLines(c('feature_id,feature_name,genome','g1,MT-one,GRCh38','g2,Gene2,GRCh38'),genef)
writeLines(c('feature_id,feature_name,genome','guide1,guide1,GRCh38','guide2,guide2,GRCh38'),guidef)
a<-list(gene_mat_fp=gene,grna_mat_fp=guide,all_genes_fp=genef,all_grnas_fp=guidef,moi='low',grna_target_data_frame=meta)
direct<-do.call(sceptre::import_data_from_parse,a)
project_prepare(list(method='parse',arguments=a,analyses=character()),config,file.path(root,'parse'))
object<-read_bundle(file.path(root,'parse','input'),config,package_identity(),file.path(root,'parse','backing'))$object
stopifnot(identical(as.matrix(sceptre::get_response_matrix(object)),as.matrix(sceptre::get_response_matrix(direct))),identical(sceptre::get_cell_covariates(object),sceptre::get_cell_covariates(direct)))
assert_error(project_prepare(list(method='parse',arguments=c(a,list(use_hdf5=TRUE)),analyses=character()),config,file.path(root,'bad-parse')),'Unsupported import')
# Frozen cis annotation and exact public exclusions/order.
pos<-data.frame(response_id=c('g1','g2'),chr='chr1',position=c(20,100))
cis<-list(discovery=list(method='cis',assembly='GRCh38-fixture',arguments=list(response_position_data_frame=pos,distance_threshold=50L)))
cfg<-project_pairs(object,config,cis)
stopifnot(identical(cfg$analysis$discovery_pairs,sceptre::construct_cis_pairs(object,distance_threshold=50L,response_position_data_frame=pos)))
assert_error(project_preflight(object,modifyList(config,list(resources=list(max_cells=1))),character()),'max_cells exceeded')
cat('PASS multi-sample 10x HDF5, CellRanger RAM/HDF5, Parse direct-public-R counts/covariates; frozen cis pairs; unsupported Parse backing and resource rejection\n')

# New files can change a raw directory reader's format choice; unchanged resume rejects.
assert_error(project_verify(file.path(root,'tenx-TRUE')),'raw directory inventory changed')
cat('PASS raw preparation source/runtime readback and added-directory-member resume rejection\n')
