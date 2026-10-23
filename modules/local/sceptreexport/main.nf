process SCEPTREEXPORT {
    tag "${meta.id}:export"
    label 'process_medium'
    cache 'deep'

    input:
    tuple val(meta), path(state, name: 'input_state')
    path config, name: 'analysis_config.rds'
    path lock, name: 'environment_lock.rds'
    path backing, name: 'backing'
    path tools_dir, name: 'pipeline_bin'

    output:
    tuple val(meta), path('exports'), emit: exports

    tuple val("${task.process}"), val("sceptre"), eval("Rscript --vanilla pipeline_bin/version-string.R environment_lock.rds"), topic: versions, emit: versions_sceptre

    when:
    task.ext.when == null || task.ext.when || error("Selected certified stages cannot be disabled with ext.when; use --analyses or --stop_after.")

    script:
    """
    Rscript --vanilla pipeline_bin/export_state.R analysis_config.rds input_state environment_lock.rds backing
    Rscript --vanilla pipeline_bin/versions.R environment_lock.rds
    """
}
