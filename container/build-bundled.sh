#!/usr/bin/env bash
# One command; no credentials, registry upload or external SCEPTRE checkout required.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/.." && pwd)
tag=${1:-sceptre-pipeline:qualified-local}
context=${SCEPTRE_BUILD_CONTEXT:-"$here/.build/bundled"}
python3 "$here/prepare-context.py" --source-manifest "$root/tests/runtime/source.json" --output "$context"
docker build --progress plain --iidfile "$context/image-id" --tag "$tag" "$context"
docker image inspect "$tag" > "$context/image-inspect.json"
printf 'Immutable local image: %s\nSource receipt: %s/source.json\n' "$(cat "$context/image-id")" "$context"
