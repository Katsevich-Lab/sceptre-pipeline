process SCEPTRE_COLLECT {
    tag "${meta.id}:${stage}:collect"
    label 'process_medium'
    cache 'deep'
    input:
    tuple val(meta), path(state, name: 'input_state')
    path config, name: 'analysis_config.rds'
    path lock, name: 'environment_lock.rds'
    path backing, name: 'backing'
    path tools_dir, name: 'pipeline_bin'
    path execution, name: 'execution'
    path proposals, name: 'proposals/*'
    val stage
    val seed
    output:
    tuple val(meta), path('state'), emit: state
    path 'versions.yml', emit: version_file
    tuple val("${task.process}"), val("sceptre"), eval("Rscript --vanilla pipeline_bin/version-string.R environment_lock.rds"), topic: versions, emit: versions_sceptre

    when:
    task.ext.when == null || task.ext.when || error("Selected certified stages cannot be disabled with ext.when; use --analyses or --stop_after.")

    script:
    """
    Rscript --vanilla pipeline_bin/distributed_stage.R collect analysis_config.rds input_state execution state '${stage}' '${seed}' 1 unused environment_lock.rds backing
    Rscript --vanilla pipeline_bin/versions.R environment_lock.rds
    """
}
