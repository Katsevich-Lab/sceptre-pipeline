#!/usr/bin/env python3
"""Validate an explicitly approved immutable review artifact; never build images."""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import urllib.request

WORKFLOW = '.github/workflows/publish-container.yml'
REPOSITORY = 'Katsevich-Lab/sceptre-pipeline'
ARCHIVE = 'f41a8fb7e1bc10366e8efcc7a31644d4c8356bc4eca8adda9ca949c951de4fb4'

def require(ok, message):
    if not ok:
        raise ValueError(message)

def expected_from_environment():
    expected = {name: os.environ['REVIEW_' + name.upper()] for name in ('run_id', 'artifact_id', 'source_sha', 'image_id', 'archive_sha256')}
    for name in ('run_id', 'artifact_id'):
        require(bool(re.fullmatch('[1-9][0-9]*', expected[name])), 'Invalid ' + name)
        expected[name] = int(expected[name])
    require(bool(re.fullmatch('[a-f0-9]{40}', expected['source_sha'])), 'Invalid source SHA')
    require(bool(re.fullmatch('sha256:[a-f0-9]{64}', expected['image_id'])), 'Invalid immutable image ID')
    require(bool(re.fullmatch('[a-f0-9]{64}', expected['archive_sha256'])), 'Invalid archive SHA256')
    return expected

def verify_origin(expected, workflow, run, artifact, jobs):
    require(workflow['path'] == WORKFLOW, 'Wrong registered workflow path')
    require(run['id'] == expected['run_id'] and run['workflow_id'] == workflow['id'], 'Wrong originating run/workflow')
    require(run['path'] == WORKFLOW and run['head_sha'] == expected['source_sha'], 'Wrong originating source')
    require(run['repository']['full_name'].lower() == REPOSITORY.lower(), 'Wrong originating repository')
    require(run['status'] == 'completed' and run['conclusion'] == 'success', 'Originating run did not succeed')
    require(run['event'] in ('push', 'workflow_dispatch') and run['head_branch'].startswith('codex/container-review-'), 'Origin is not a dedicated review branch build')
    require(sum(job['name'] == 'build-review' and job['conclusion'] == 'success' and job['status'] == 'completed' for job in jobs) == 1, 'No unique successful latest-attempt build-review job')
    require(artifact['id'] == expected['artifact_id'] and not artifact['expired'] and artifact['size_in_bytes'] > 0, 'Wrong, empty or expired artifact')
    require(bool(re.fullmatch('sha256:[a-f0-9]{64}', artifact.get('digest', ''))), 'Missing GitHub artifact digest')
    require(artifact['name'] == f"reviewed-exact-source-image-{run['id']}-{run['run_attempt']}", 'Artifact is not from successful latest attempt')
    require(artifact['workflow_run']['id'] == run['id'] and artifact['workflow_run']['head_sha'] == expected['source_sha'], 'Artifact does not belong to approved run/source')
    return {'kind': 'approved-image-origin', 'expected': expected, 'repository': REPOSITORY,
            'workflow_id': workflow['id'], 'run_attempt': run['run_attempt'], 'run_event': run['event'],
            'artifact_name': artifact['name'], 'artifact_digest': artifact.get('digest'),
            'run_url': run['html_url'], 'status': 'VERIFIED'}

def file_hash(path):
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for block in iter(lambda: handle.read(1048576), b''):
            digest.update(block)
    return digest.hexdigest()

def verify_local(directory, origin, loaded=False):
    expected = origin['expected']
    load = lambda path: json.loads((directory / path).read_text())
    receipt = load('review-receipt.json')
    require(receipt['kind'] == 'scientifically-qualified-image-review' and receipt['status'] == 'PASS', 'Missing successful scientific review')
    for name in ('run_id', 'source_sha', 'image_id', 'archive_sha256'):
        require(receipt[name] == expected[name], 'Review receipt mismatch: ' + name)
    require(receipt['review_helpers_sha256'] == origin['review_helpers_sha256'], 'Review helper bytes are not bound to approved source')
    require(receipt['approval_input'] is False, 'Review artifact was not a no-publication build')
    require(receipt['run_attempt'] == origin['run_attempt'], 'Review receipt attempt mismatch')
    require(receipt['repository'].lower() == REPOSITORY.lower(), 'Review repository mismatch')
    require(receipt['gates'] == ['installed-package', 'native-HDF5-public-R-all-families', 'power-checkpoint', 'unchanged-resume', 'source-unchanged'], 'Incomplete scientific qualification gates')
    require((directory / 'image-id').read_text().strip() == expected['image_id'], 'Image identity file mismatch')
    require((directory / 'image.sha256').read_text().split() == [expected['archive_sha256'], 'image.tar.gz'], 'Archive checksum file mismatch')
    require(file_hash(directory / 'image.tar.gz') == expected['archive_sha256'], 'Archive bytes differ from approved SHA256')
    before = load('source-before.json'); after = load('source-after.json')
    require(before == after and before['git_head'] == expected['source_sha'], 'Source changed or wrong checkout')
    require(before['production_sha256'] == receipt['production_sha256'] and before['qualification_sha256'] == receipt['qualification_sha256'], 'Source identity receipt mismatch')
    require(before['scientific_archive_sha256'] == ARCHIVE and load('context/source.json').get('sceptre_archive_sha256') == ARCHIVE, 'Wrong selected scientific archive')
    require(load('scientific-parity/source-before.json') == load('scientific-parity/source-after.json'), 'Scientific source changed')
    engine = load('host-engine.json')
    require(engine['nextflow_version'] == '25.10.4' and engine['parser_override'] is None, 'Wrong Nextflow runtime')
    require(engine['java']['java.vendor'] == 'Eclipse Adoptium' and engine['java']['java.runtime.version'] == '17.0.10+7', 'Wrong JVM runtime')
    image = load('loaded-inspect.json' if loaded else 'image-inspect.json')[0]
    require(image['Id'] == expected['image_id'] and image['Architecture'] == 'amd64' and image['Os'] == 'linux', 'Loaded/reviewed image identity or platform mismatch')
    labels = image['Config']['Labels']
    require(labels['org.opencontainers.image.revision'] == expected['source_sha'] and labels['org.opencontainers.image.source'] == 'https://github.com/' + REPOSITORY, 'OCI source/revision mismatch')
    return {'status': 'VERIFIED', 'expected': expected, 'loaded_image_checked': loaded}

def api(path):
    require(os.environ['GITHUB_REPOSITORY'].lower() == REPOSITORY.lower(), 'Wrong promotion repository')
    request = urllib.request.Request('https://api.github.com/repos/' + REPOSITORY + path,
        headers={'Authorization': 'Bearer ' + os.environ['GH_TOKEN'], 'Accept': 'application/vnd.github+json', 'X-GitHub-Api-Version': '2022-11-28'})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=['origin', 'local', 'loaded']); parser.add_argument('output', type=Path)
    args = parser.parse_args()
    if args.mode == 'origin':
        expected = expected_from_environment()
        run = api('/actions/runs/' + str(expected['run_id']))
        workflow = api('/actions/workflows/publish-container.yml')
        artifact = api('/actions/artifacts/' + str(expected['artifact_id']))
        jobs = api('/actions/runs/' + str(expected['run_id']) + '/attempts/' + str(run['run_attempt']) + '/jobs?per_page=100')
        require(jobs['total_count'] <= 100, 'Unexpected originating job count')
        result = verify_origin(expected, workflow, run, artifact, jobs['jobs'])
        helpers = {}
        for name in ('review_image.py', 'test_review_image.py'):
            entry = api('/contents/.github/scripts/' + name + '?ref=' + expected['source_sha'])
            require(entry['encoding'] == 'base64', 'Unexpected helper source encoding')
            helpers[name] = hashlib.sha256(base64.b64decode(entry['content'])).hexdigest()
        result['review_helpers_sha256'] = helpers
    else:
        origin = json.loads(Path('origin.json').read_text())
        require(origin['expected'] == expected_from_environment(), 'Origin admission inputs changed')
        result = verify_local(Path('image'), origin, args.mode == 'loaded')
    args.output.write_text(json.dumps(result, indent=2) + '\n')
    print('PASS approved artifact ' + args.mode + ' identity; no rebuild')

if __name__ == '__main__':
    main()
