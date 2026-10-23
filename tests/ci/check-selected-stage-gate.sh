#!/usr/bin/env bash
# A site override may not silently erase requested certified work.
set -euo pipefail
root=${1:?Usage: tests/ci/check-selected-stage-gate.sh NEW_OUTPUT_ROOT}
: "${SCEPTRE_CONTAINER_IMAGE:?Set exact qualified image identity}"
mkdir -p "$root"
root=$(cd "$root" && pwd)
docker run --rm -v "$PWD:$PWD" -v "$root:$root" -w "$PWD" "$SCEPTRE_CONTAINER_IMAGE" Rscript --vanilla tests/make-input.R "$root/fixture"
printf 'process.ext.when = false\n' > "$root/disable.config"
if nextflow run . -profile test,docker -c "$root/disable.config" \
 --container_image "$SCEPTRE_CONTAINER_IMAGE" --input_bundle "$root/fixture/input" \
 --analysis_config "$root/fixture/config.rds" --environment_lock "$root/fixture/lock.rds" \
 --outdir "$root/results" -work-dir "$root/work" > "$root/nextflow.log" 2>&1; then
 echo 'ERROR selected stages were silently skipped' >&2
 exit 1
fi
python3 - "$root" <<'PY'
from pathlib import Path
import sys
root=Path(sys.argv[1]); log=(root/'nextflow.log').read_text()
assert any(message in log for message in ('Selected certified stages cannot be disabled with ext.when', 'A selected certified stage produced no state')),log
assert not (root/'results'/'exports').exists()
assert not (root/'results'/'parameters').exists()
print('PASS false ext.when is an explicit failure before certified outputs')
PY
