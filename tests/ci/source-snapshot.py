#!/usr/bin/env python3
"""Record portable production-source identities without copying external/site secrets."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[2]
paths = {root / name for name in ('main.nf', 'nextflow.config', 'nextflow_schema.json', 'demo/make-input.R')}
for pattern in ('bin/*', 'conf/*.config', 'modules/**/*.nf', 'subworkflows/**/*.nf'):
    paths.update(p for p in root.glob(pattern) if p.is_file())
identities = {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths)}
receipt = {
    'kind': 'sceptre-pipeline-portable-source-snapshot', 'schema': 1,
    'git_head': subprocess.check_output(['git', '-C', str(root), 'rev-parse', 'HEAD'], text=True).strip(),
    'production_sha256': hashlib.sha256(json.dumps(identities, sort_keys=True, separators=(',', ':')).encode()).hexdigest(),
    'files_sha256': identities,
    'scientific_archive_sha256': hashlib.sha256((root / 'tests/runtime/sceptre_0.99.0.tar.gz').read_bytes()).hexdigest(),
    'limits': 'Source identity only; execution, external-config and runtime identities require their separate receipts.'
}
text = json.dumps(receipt, indent=2, sort_keys=True) + '\n'
if args.output:
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(text)
else:
    print(text, end='')
