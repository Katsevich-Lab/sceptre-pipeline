#!/usr/bin/env python3
"""Real Nextflow regression: tracked configs cannot hide external include changes."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('output', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
out = args.output.resolve()
out.mkdir(parents=True, exist_ok=False)
image = os.environ['SCEPTRE_CONTAINER_IMAGE']
fixture = out / 'fixture'
subprocess.run(['docker', 'run', '--rm', '-v', f'{root}:{root}', '-v', f'{out}:{out}',
                '-w', str(root), image, 'Rscript', '--vanilla', 'tests/make-input.R', str(fixture)], check=True)
results = []

def copy_project(destination):
    destination.mkdir()
    for name in ['bin', 'conf', 'demo', 'modules', 'subworkflows', 'resources']:
        shutil.copytree(root / name, destination / name)
    for name in ['main.nf', 'nextflow.config', 'nextflow_schema.json']:
        shutil.copyfile(root / name, destination / name)
    return destination


def run(project, case, label, extra=(), resume=False, success=True, diagnostic=None):
    (case / 'request.json').write_text(json.dumps({'analyses': ''}))
    command = ['nextflow', 'run', str(project / 'main.nf'), '-profile', 'test,docker',
               '--container_image', image, '--input_bundle', str(fixture / 'input'),
               '--analysis_config', str(fixture / 'config.rds'), '--environment_lock', str(fixture / 'lock.rds'),
               '--outdir', str(case / 'results'), '--stop_after', 'parameters', '-params-file', str(case / 'request.json'),
               '-work-dir', str(case / 'work'), *extra]
    if resume:
        command.append('-resume')
    with (case / f'{label}.log').open('w') as handle:
        completed = subprocess.run(command, cwd=case, stdout=handle, stderr=subprocess.STDOUT)
    text = (case / f'{label}.log').read_text()
    assert (completed.returncode == 0) == success, text
    if diagnostic:
        diagnostics = [diagnostic] if isinstance(diagnostic, str) else diagnostic
        assert any(expected in text for expected in diagnostics), text
    results.append({'case': case.name, 'phase': label, 'exit_code': completed.returncode,
                    'expected_success': success, 'command': command,
                    'matched_rejection': [expected for expected in diagnostics if expected in text] if diagnostic else []})


def signature(case, label):
    path = case / 'results/run_signature.rds'
    command = ['docker', 'run', '--rm', '-v', f'{out}:{out}', image, 'Rscript', '--vanilla', '-e',
               'a<-commandArgs(TRUE);jsonlite::write_json(readRDS(a[1]),a[2],auto_unbox=TRUE,pretty=TRUE)',
               str(path), str(case / f'{label}-signature.json')]
    subprocess.run(command, check=True)
    return json.loads((case / f'{label}-signature.json').read_text())

for topology in ['tracked-external', 'external-tracked-external']:
    case = out / topology
    case.mkdir()
    project = copy_project(case / 'project')
    extra = []
    if topology == 'tracked-external':
        leaf = project / 'site.config'
        with (project / 'conf/base.config').open('a') as handle:
            handle.write("\nincludeConfig '../site.config' // trailing includeConfig text is a comment\nenv.SCEPTRE_CONFIG_CLOSURE_AFTER = 'ordinary next statement'\n")
    else:
        leaf = case / 'leaf.config'
        (project / 'conf/bridge.config').write_text("includeConfig '../../leaf.config'\n")
        outer = case / 'outer.config'
        outer.write_text("includeConfig 'project/conf/bridge.config'\n")
        extra = ['-c', str(outer)]
    # Words inside comments/strings must not be mistaken for include calls.
    leaf.write_text("// includeConfig dynamicIgnored\n/* includeConfig ignored */\nenv.SCEPTRE_CONFIG_CLOSURE_NOTE = 'includeConfig is only text'\nenv.SCEPTRE_CONFIG_CLOSURE_MARKER = 'one'\n")
    run(project, case, 'initial', extra)
    initial = signature(case, 'initial')
    expected = hashlib.sha256(leaf.read_bytes()).hexdigest()
    digests = initial['options']['external_config_sha256']
    if isinstance(digests, str):
        digests = [digests]
    expected_digests = [expected]
    if extra:
        expected_digests.append(hashlib.sha256(outer.read_bytes()).hexdigest())
    assert sorted(expected_digests) == sorted(digests), (topology, initial)
    before = {str(p.relative_to(case / 'results')): hashlib.sha256(p.read_bytes()).hexdigest()
              for p in (case / 'results').rglob('*') if p.is_file() and 'pipeline_info' not in p.parts}
    run(project, case, 'unchanged-resume', extra, resume=True)
    assert initial == signature(case, 'unchanged-resume')
    assert 'Cached process > SCEPTRE:PARAMETERS' in (case / 'unchanged-resume.log').read_text()
    leaf.write_text(leaf.read_text().replace("= 'one'", "= 'two'"))
    run(project, case, 'mutated-resume', extra, resume=True, success=False,
        diagnostic='Output directory belongs to a different run')
    after = {str(p.relative_to(case / 'results')): hashlib.sha256(p.read_bytes()).hexdigest()
             for p in (case / 'results').rglob('*') if p.is_file() and 'pipeline_info' not in p.parts}
    assert before == after, (topology, 'failed resume altered certified publication')
    assert not (case / 'results/exports').exists()

# Each is valid Nextflow configuration but unsupported identity syntax. Reject
# before scientific task admission instead of binding only a literal prefix.
for name, statement, diagnostic in [
    ('dynamic-variable', "params.modules_testdata_base_path = 'leaf.config'\nincludeConfig params.modules_testdata_base_path\n", 'Configuration identity supports only literal local includeConfig paths'),
    ('concatenation', "includeConfig 'leaf' + '.config'\n", 'Configuration identity supports only literal local includeConfig paths'),
    ('comment-concatenation', "includeConfig 'leaf' /* joined */ + '.config'\n", 'Configuration identity supports only literal local includeConfig paths'),
    ('comment-repeat', "includeConfig 'leaf' /* joined */ * 2\n", 'Configuration identity supports only literal local includeConfig paths'),
    ('comment-method', "includeConfig 'leaf' /* joined */ .plus('.config')\n", 'Configuration identity supports only literal local includeConfig paths'),
    ('newline-concatenation', "includeConfig('leaf'\n + '.config')\n", 'Configuration identity supports only literal local includeConfig paths'),
    ('hidden-interpolation', "env.SCEPTRE_CONFIG_CLOSURE_HIDDEN = \"${includeConfig('leaf.config')}\"\n", (['Configuration identity cannot inspect includeConfig inside string interpolation', '`includeConfig` is not defined'] if os.environ.get('NXF_VER', '').startswith('26.') else 'Configuration identity cannot inspect includeConfig inside string interpolation')),
]:
    case = out / name
    case.mkdir()
    project = copy_project(case / 'project')
    for leaf_name in ['leaf.config', 'leafleaf']:
        (case / leaf_name).write_text("env.SCEPTRE_CONFIG_CLOSURE_MARKER = 'one'\n")
    config = case / 'unsupported.config'
    config.write_text(statement)
    if os.environ.get('NXF_VER', '').startswith('26.') and name in ['comment-concatenation', 'newline-concatenation']:
        diagnostic = [diagnostic, "Unexpected input: '+'"]
    run(project, case, 'rejected', ['-c', str(config)], success=False,
        diagnostic=diagnostic)
    assert 'Submitted process' not in (case / 'rejected.log').read_text()
    assert not (case / 'results/parameters').exists()
    assert not (case / 'results/run_signature.rds').exists()

(out / 'receipt.json').write_text(json.dumps({'kind': 'nextflow-config-closure-regression',
    'nextflow_requested': os.environ.get('NXF_VER'), 'parser_override': os.environ.get('NXF_SYNTAX_PARSER'),
    'container_image': image, 'topologies': 2, 'negative_syntax_cases': 7,
    'status': 'PASS', 'runs': results}, indent=2) + '\n')
print('PASS tracked→external and external→tracked→external exact digest binding, unchanged resume, mutation rejection/no publication, and seven dynamic-expression guards')
