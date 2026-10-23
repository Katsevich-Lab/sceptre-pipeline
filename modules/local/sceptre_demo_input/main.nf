process SCEPTRE_DEMO_INPUT {
    tag 'synthetic-source-pinned-screen'
    label 'process_single'
    cache 'deep'
    input:
    path tools_dir, name: 'bin'
    path demo_dir, name: 'demo'
    output:
    path 'fixture', emit: fixture
    tuple val("${task.process}"), val("sceptre"), eval("Rscript --vanilla bin/version-string.R fixture/lock.rds"), topic: versions, emit: versions_sceptre
    when:
    task.ext.when == null || task.ext.when || error("Selected synthetic preparation cannot be disabled with ext.when.")
    script:
    """
    Rscript --vanilla demo/make-input.R fixture
    """
}
