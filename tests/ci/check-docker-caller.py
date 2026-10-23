#!/usr/bin/env python3
"""Prove numeric nonroot UID/GID and ownership inside native Linux Docker storage."""
import json
import os
from pathlib import Path
import subprocess
import sys
import uuid

output = Path(sys.argv[1]).resolve()
image = os.environ['SCEPTRE_CONTAINER_IMAGE']
repo = Path(__file__).resolve().parents[2]
volume = 'sceptre-caller-' + uuid.uuid4().hex

def run(*args, capture=False):
    return subprocess.check_output(args, text=True) if capture else subprocess.run(args, check=True)

run('docker', 'volume', 'create', volume)
try:
    run('docker', 'run', '--rm', '-v', volume + ':/probe', image, 'sh', '-c',
        'chown 1001:1002 /probe && chmod 700 /probe')
    base = ['docker', 'run', '--rm', '--user', '1001:1002', '-e', 'HOME=/tmp', '-e', 'R_LIBS_USER=/nonexistent',
            '-v', volume + ':/probe', '-v', str(repo) + ':/source:ro', image]
    run(*base, 'Rscript', '--vanilla', '/source/bin/verify_runtime.R', '/source/tests/runtime/source.json')
    code = """
stopifnot(identical(system('id -u', intern=TRUE), '1001'),
          identical(system('id -g', intern=TRUE), '1002'),
          identical(Sys.getenv('HOME'), '/tmp'),
          identical(Sys.getenv('R_LIBS_USER'), '/nonexistent'))
dir.create('/probe/prepared')
writeLines('caller-created', '/probe/prepared/params.json')
info <- file.info(c('/probe/prepared','/probe/prepared/params.json'))
stopifnot(all(info$uid == 1001L), all(info$gid == 1002L))
writeLines('caller-edited', '/probe/prepared/params.json')
stopifnot(unlink('/probe/prepared', recursive=TRUE) == 0L,
          !dir.exists('/probe/prepared'))
jsonlite::write_json(list(container_uid=1001L,container_gid=1002L,
  home=Sys.getenv('HOME'),r_libs_user=Sys.getenv('R_LIBS_USER'),
  library_paths=.libPaths(),native_linux_named_volume=TRUE,
  create_edit_delete=TRUE,qualified_runtime_verified=TRUE),
  '/probe/receipt.json',pretty=TRUE,auto_unbox=TRUE)
"""
    run(*base, 'Rscript', '--vanilla', '-e', code)
    receipt = json.loads(run('docker', 'run', '--rm', '-v', volume + ':/probe:ro', image,
                             'cat', '/probe/receipt.json', capture=True))
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(receipt, indent=2) + '\n')
    print('PASS actual Linux Docker UID1001/GID1002 qualified R and caller create/edit/delete; host bind mapping not used')
finally:
    run('docker', 'volume', 'rm', volume)
