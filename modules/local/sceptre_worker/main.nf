process SCEPTRE_WORKER {
    tag "${meta.id}:${stage}:${unit_id}"
    label 'process_medium'
    array (params.worker_arrays ? params.array_size : null)
    cache 'deep'
    input:
    tuple val(meta), path(state, name: 'input_state')
    path config, name: 'analysis_config.rds'
    path lock, name: 'environment_lock.rds'
    path backing, name: 'backing'
    path tools_dir, name: 'pipeline_bin'
    path execution, name: 'execution'
    val stage
    val seed
    val unit_id
    output:
    val meta, emit: meta
    path "proposal_${unit_id}.rds", emit: proposal
    path 'versions.yml', emit: version_file
    tuple val("${task.process}"), val("sceptre"), eval("Rscript --vanilla pipeline_bin/version-string.R environment_lock.rds"), topic: versions, emit: versions_sceptre

    when:
    task.ext.when == null || task.ext.when || error("Selected certified stages cannot be disabled with ext.when; use --analyses or --stop_after.")

    script:
    """
    Rscript --vanilla pipeline_bin/distributed_stage.R worker analysis_config.rds input_state execution 'proposal_${unit_id}.rds' '${stage}' '${seed}' 1 '${unit_id}' environment_lock.rds backing
    Rscript --vanilla pipeline_bin/versions.R environment_lock.rds
    """
}
