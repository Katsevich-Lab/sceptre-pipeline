#!/usr/bin/env python3
"""Assert the final installed host engine, after all composite setup actions."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('nextflow_version')
parser.add_argument('receipt', type=Path)
args = parser.parse_args()
if os.environ.get('NXF_SYNTAX_PARSER'):
    parser.error('CI must qualify each pinned Nextflow release with its supported parser default')
if os.environ.get('NXF_VER') != args.nextflow_version:
    parser.error('NXF_VER does not match the pinned engine requested by this job')
java_home = os.environ.get('JAVA_HOME')
if not java_home:
    parser.error('Final setup did not declare JAVA_HOME')
if os.environ.get('NXF_JAVA_HOME') and Path(os.environ['NXF_JAVA_HOME']).resolve() != Path(java_home).resolve():
    parser.error('NXF_JAVA_HOME would override the qualified JAVA_HOME')
java = Path(java_home) / 'bin/java'
if os.environ.get('JAVA_CMD') and Path(os.environ['JAVA_CMD']).resolve() != java.resolve():
    parser.error('JAVA_CMD would override the qualified JAVA_HOME executable')
java_result = subprocess.run([str(java), '-XshowSettings:properties', '-version'], check=True, capture_output=True, text=True)
java_text = java_result.stdout + java_result.stderr
properties = dict(re.findall(r'^\s*(java\.(?:runtime\.version|vendor|version))\s*=\s*(.*?)\s*$', java_text, re.M))
if properties.get('java.runtime.version') != '17.0.10+7' or properties.get('java.vendor') != 'Eclipse Adoptium':
    parser.error('Final JVM differs from pinned Temurin17.0.10+7: ' + repr(properties))
nextflow = shutil.which('nextflow')
if not nextflow:
    parser.error('Nextflow is not installed')
nf_result = subprocess.run([nextflow, '-version'], check=True, capture_output=True, text=True)
nf_text = nf_result.stdout + nf_result.stderr
version = re.search(r'\bversion\s+(\d+\.\d+\.\d+(?:-edge)?)\b', nf_text)
if not version or version.group(1) != args.nextflow_version:
    parser.error('Installed Nextflow differs from the requested exact release: ' + nf_text)
args.receipt.parent.mkdir(parents=True, exist_ok=True)
args.receipt.with_suffix('.java.txt').write_text(java_text)
args.receipt.with_suffix('.nextflow.txt').write_text(nf_text)
receipt = dict(kind='sceptre-pipeline-host-engine', schema=1, java_home=java_home,
               java_executable_sha256=hashlib.sha256(java.read_bytes()).hexdigest(),
               java=properties, nextflow_version=version.group(1), parser_override=None,
               policy='Exact final Temurin patch/vendor and Nextflow release verified after composite setup; supported parser defaults retained.')
args.receipt.write_text(json.dumps(receipt, indent=2) + '\n')
print('PASS final JVM Temurin17.0.10+7 and Nextflow' + args.nextflow_version + '; supported parser default')
