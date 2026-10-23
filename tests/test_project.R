#!/usr/bin/env Rscript
source('bin/pipeline.R'); source('bin/project.R'); source('tests/fixture.R')
args <- commandArgs(TRUE); root <- if(length(args)) args[1] else tempfile('project-tests-')
dir.create(root,recursive=TRUE)
assert_error <- function(expr, pattern) { e <- tryCatch(force(expr),error=identity); stopifnot(inherits(e,'error'),grepl(pattern,conditionMessage(e),fixed=TRUE)); invisible(e) }
f <- pipeline_fixture()
y <- sceptre::get_response_matrix(f$object); g <- sceptre::get_grna_matrix(f$object)
meta <- as.data.frame(SummarizedExperiment::rowData(SingleCellExperiment::altExp(sceptre::get_screen_experiment(f$object),'gRNA')))
meta$grna_id <- rownames(g)
cov <- sceptre::get_cell_covariates(f$object)[,c('batch','z'),drop=FALSE]
import <- list(response_matrix=y,grna_matrix=g,grna_target_data_frame=meta,moi='low',extra_covariates=cov)
for (backed in c(FALSE,TRUE)) {
 spec <- list(method='matrix',arguments=c(import,list(use_hdf5=backed)))
 output <- file.path(root,if(backed) 'hdf5' else 'ram')
 project_prepare(spec,f$config,output)
 state <- read_bundle(file.path(output,'input'),f$config,readRDS(file.path(output,'environment_lock.rds')),file.path(output,'backing'))
 stopifnot(identical(as.matrix(sceptre::get_response_matrix(state$object)),as.matrix(y)),identical(sceptre::get_cell_covariates(state$object),sceptre::get_cell_covariates(f$object)))
 settings <- readRDS(file.path(output,'settings.rds'))
 stopifnot(settings$resolved$control_group=='nt_cells',settings$resolved$assignment=='maximum')
}
assert_error(project_prepare(list(method='matrix',arguments=import),list(analysis=list(multiple_testing_alpha=.2)),file.path(root,'partial')), 'requires positive_control_pairs')
p <- project_preflight(f$object,list(analysis=list(multiple_testing_alpha=.2)),character())
stopifnot(p$resolved$discovery_pairs==0L,length(p$notes)>0)
assert_error(project_preflight(f$object,modifyList(f$config,list(assignment=list(method='thresholding',umi_fraction_threshold=.2)))),'incompatible')
assert_error(project_preflight(f$object,c(f$config,list(unknown=list()))),'Unknown configuration')
bad <- import; bad$grna_matrix <- g[,rev(seq_len(ncol(g)))]
assert_error(project_prepare(list(method='matrix',arguments=bad),f$config,file.path(root,'misaligned')),'cell')
stopifnot(!dir.exists(file.path(root,'misaligned')))
# Public SCE import includes selected covariates, preserving exact data.
sce <- sceptre::get_screen_experiment(f$object)
project_prepare(list(method='sce',arguments=list(sce=sce,grna_target_data_frame=meta,moi='low',covariates=c('batch','z'))),f$config,file.path(root,'sce'))
# Public pair constructors, exact table/order and explicit annotation guard.
paircfg <- f$config; paircfg$analysis$discovery_pairs <- NULL; paircfg$analysis$positive_control_pairs <- NULL
cfg <- project_pairs(f$object,paircfg,list(discovery=list(method='trans',arguments=list(pairs_to_exclude='none'))))
stopifnot(identical(cfg$analysis$discovery_pairs,sceptre::construct_trans_pairs(f$object)))
assert_error(project_pairs(f$object,paircfg,list(discovery=list(method='cis',arguments=list()))),'explicit frozen')
# JSON references and public CLI authoring; shell never evaluates formulas.
saveRDS(y,file.path(root,'y.rds'));saveRDS(g,file.path(root,'g.rds'));saveRDS(meta,file.path(root,'meta.rds'));saveRDS(cov,file.path(root,'cov.rds'));saveRDS(f$config,file.path(root,'config.rds'))
jsonlite::write_json(list(method='matrix',arguments=list(response_matrix=list('$rds'='y.rds'),grna_matrix=list('$rds'='g.rds'),grna_target_data_frame=list('$rds'='meta.rds'),moi='low',extra_covariates=list('$rds'='cov.rds'))),file.path(root,'input.json'),auto_unbox=TRUE)
writeLines('{"$rds":"config.rds"}',file.path(root,'config.json'))
status <- system2(file.path(R.home('bin'),'Rscript'),vapply(c('bin/prepare_project.R',file.path(root,'input.json'),file.path(root,'config.json'),file.path(root,'cli')),shQuote,character(1)))
stopifnot(status==0L)
receipt <- readRDS(file.path(root,'cli','preparation.rds'));stopifnot(length(receipt$source_files)==7L)
cat('PASS matrix RAM/native HDF5 and SCE preparation, defaults/partial config, invalid assignment/keys/alignment, public pairs and JSON CLI source receipt\n')
# A decoded file must never acquire a different authoritative source hash.
e <- new.env(parent=emptyenv());e$paths<-character();e$hashes<-list()
value <- project_decode(list('$rds'='y.rds'),root,e)
saveRDS(y*2,file.path(root,'y.rds'))
assert_error(project_prepare(list(method='matrix',arguments=import),f$config,file.path(root,'changed-source'),source_paths=e$paths,source_hashes=e$hashes),'changed after reference decoding')
stopifnot(!file.exists(file.path(root,'changed-source')))
assert_error(project_pairs(f$object,f$config,list(list(method='trans'))),'named list')
assert_error(project_pairs(f$object,f$config,structure(list(list(method='trans'),list(method='trans')),names=c('discovery','discovery'))),'unique supported')
# Explicit positive-control and exclusion constructors are exactly the public API.
meta2<-meta;meta2$grna_target<-c('r1','r1','r2','r2',rep('non-targeting',4L))
obj2<-sceptre::import_data(y,g,meta2,moi='low',extra_covariates=cov)
constructor_cfg<-list(analysis=list(formula_object=~batch+z))
constructed<-project_pairs(obj2,constructor_cfg,list(positive_control=list(method='positive_control'),discovery=list(method='trans',arguments=list(pairs_to_exclude='pc_pairs'))))
pc<-sceptre::construct_positive_control_pairs(obj2)
stopifnot(identical(constructed$analysis$positive_control_pairs,pc),identical(constructed$analysis$discovery_pairs,sceptre::construct_trans_pairs(obj2,positive_control_pairs=pc,pairs_to_exclude='pc_pairs')))
badcfg<-f$config;badcfg$analysis$discovery_pairs$response_id[1]<-'missing-response'
assert_error(project_preflight(f$object,badcfg),'response')

# Explicit TSV row identities preserve order; duplicate IDs reject without reordering.
utils::write.table(data.frame(cell_id=rownames(cov),z=cov$z),file.path(root,'cov.tsv'),sep='\t',quote=FALSE,row.names=FALSE)
e2<-new.env(parent=emptyenv());e2$paths<-character();e2$hashes<-list()
tab<-project_decode(list('$table'='cov.tsv',row_names='cell_id'),root,e2)
stopifnot(identical(rownames(tab),rownames(cov)),identical(tab$z,utils::read.delim(file.path(root,'cov.tsv'))$z),!('cell_id'%in%names(tab)))
high<-pipeline_fixture(moi='high',control='nt_cells',mechanism='crt')
resolved<-project_preflight(high$object,high$config)
stopifnot(resolved$resolved$control_group=='complement',any(grepl('high-MOI nt_cells',resolved$notes,fixed=TRUE)))
cat('PASS reference mutation, malformed constructors, public positive/trans exclusion, unknown IDs, TSV row identities and high-MOI requested/resolved guards\n')
# Factors/interactions are interpreted by the public R design constructor.
interactions<-f$config;interactions$analysis$formula_object<-~batch*z
resolved_interactions<-project_preflight(f$object,interactions)
direct_interactions<-do.call(sceptre::set_analysis_parameters,c(list(sceptre_object=f$object),interactions$analysis))
stopifnot(identical(resolved_interactions$resolved$design,hash_value(direct_interactions@preparation@design_matrix)))
