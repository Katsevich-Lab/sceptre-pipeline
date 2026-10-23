process SCEPTREPREPARE {
    tag "${meta.id}:${stage}:prepare"
    label 'process_single'
    cache 'deep'
    input:
    tuple val(meta), path(state, name: 'input_state')
    path config, name: 'analysis_config.rds'
    path lock, name: 'environment_lock.rds'
    path backing, name: 'backing'
    path tools_dir, name: 'pipeline_bin'
    val stage
    val seed
    val n_units
    output:
    val meta, emit: meta
    path 'execution', emit: execution
    path 'execution/unit_ids.txt', emit: units
    path 'versions.yml', emit: version_file
    tuple val("${task.process}"), val("sceptre"), eval("Rscript --vanilla pipeline_bin/version-string.R environment_lock.rds"), topic: versions, emit: versions_sceptre

    when:
    task.ext.when == null || task.ext.when || error("Selected certified stages cannot be disabled with ext.when; use --analyses or --stop_after.")

    script:
    """
    Rscript --vanilla pipeline_bin/distributed_stage.R prepare analysis_config.rds input_state unused execution '${stage}' '${seed}' '${n_units}' unused environment_lock.rds backing
    Rscript --vanilla pipeline_bin/versions.R environment_lock.rds
    """
}
