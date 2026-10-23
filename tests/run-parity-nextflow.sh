#!/usr/bin/env bash
set -euo pipefail
repo=$(pwd)
run_dir=${1:?Usage: tests/run-parity-nextflow.sh NEW_RUN_DIRECTORY}
mkdir -p "$run_dir"
run_dir=$(cd "$run_dir" && pwd)
source_snapshot() {
 python3 - "$repo" "$1" <<'PY_SOURCE'
import hashlib,json,pathlib,sys
repo,out=map(pathlib.Path,sys.argv[1:])
paths={repo/'main.nf',repo/'nextflow.config',repo/'nextflow_schema.json'}
for pattern in ('bin/*.R','conf/*.config','modules/**/*.nf','subworkflows/**/*.nf','tests/run-parity-nextflow.sh','tests/make-parity-input.R','tests/compare-checkpoint.R','tests/check-resolved-settings.R','tests/runtime/source.json','tests/runtime/sceptre_0.99.0.tar.gz'):
 paths.update(repo.glob(pattern))
result={str(p.relative_to(repo)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths) if p.is_file()}
out.write_text(json.dumps(result,indent=2)+'\n')
PY_SOURCE
}
source_snapshot "$run_dir/source-before.json"
engine=${SCEPTRE_CONTAINER_ENGINE:-docker}
run_r() {
 if [[ -n "${SCEPTRE_CONTAINER_IMAGE:-}" && "$engine" == apptainer ]]; then
  apptainer exec --cleanenv --bind "$repo:$repo" --bind "$run_dir:$run_dir" --pwd "$repo" "$SCEPTRE_CONTAINER_IMAGE" Rscript --vanilla "$@"
 elif [[ -n "${SCEPTRE_CONTAINER_IMAGE:-}" ]]; then
  docker run --rm -v "$repo:$repo" -v "$run_dir:$run_dir" -w "$repo" "$SCEPTRE_CONTAINER_IMAGE" Rscript --vanilla "$@"
 else Rscript --vanilla "$@"; fi
}
run_r tests/make-parity-input.R "$run_dir"
profile=test
if [[ -n "${SCEPTRE_CONTAINER_IMAGE:-}" ]]; then profile="test,$engine"; fi
common=(run "$repo/main.nf" -profile "$profile" -ansi-log false -params-file "$run_dir/prepared/params.json" --execution_mode distributed --n_work_units 3)
if [[ -n "${SCEPTRE_CONTAINER_IMAGE:-}" ]]; then
 common+=(--container_image "$SCEPTRE_CONTAINER_IMAGE")
 if [[ "$engine" == apptainer ]]; then
  checksum=$(python3 - "$SCEPTRE_CONTAINER_IMAGE" <<'PY_SIF'
import hashlib,sys
h=hashlib.sha256()
with open(sys.argv[1],'rb') as f:
 for chunk in iter(lambda:f.read(1048576),b''):h.update(chunk)
print(h.hexdigest())
PY_SIF
)
  common+=(--container_image_sha256 "$checksum")
 fi
fi
(cd "$run_dir" && nextflow "${common[@]}" -work-dir "$run_dir/work" --outdir "$run_dir/full")
run_r tests/ci/compare-workflow.R "$run_dir/prepared" "$run_dir/full" 271828 analysis calibration,power,discovery "$run_dir/prepared/backing"
python3 - "$run_dir/full/pipeline_info/trace.tsv" "$run_dir/resource-observations.json" <<'PY_METRICS'
import csv,json,os,sys
rows=list(csv.DictReader(open(sys.argv[1]),delimiter='\t'))
fields=('name','status','duration','realtime','%cpu','peak_rss','peak_vmem','rchar','wchar')
receipt={'scope':'bounded synthetic 160-cell native HDF5 CRT complete calibration/power/discovery; three units',
 'container_image':os.environ.get('SCEPTRE_CONTAINER_IMAGE'), 'container_engine':os.environ.get('SCEPTRE_CONTAINER_ENGINE','docker'),
 'limits':'Observed task metrics only, not full Gasperini/Replogle or arbitrary scale assurance. macOS host-only execution does not report peak RSS.',
 'tasks':[{k:r[k] for k in fields if k in r} for r in rows]}
with open(sys.argv[2],'x') as f:json.dump(receipt,f,indent=2);f.write('\n')
PY_METRICS
# New workflow at the current completed power checkpoint. Only discovery remains.
continuation=("${common[@]}" -work-dir "$run_dir/continued-work" --input_bundle "$run_dir/full/power/state" --checkpoint_stage power --analyses discovery --outdir "$run_dir/continued")
(cd "$run_dir" && nextflow "${continuation[@]}")
run_r tests/compare-checkpoint.R "$run_dir/prepared" "$run_dir/full" "$run_dir/continued"
run_r tests/check-resolved-settings.R "$run_dir/prepared" "$run_dir/full" "$run_dir/continued"
session=$(run_r -e 'cat(readRDS(commandArgs(TRUE)[1])$options$session_id)' "$run_dir/continued/run_signature.rds")
(cd "$run_dir" && nextflow "${continuation[@]}" -resume "$session")
python3 - "$run_dir/continued/pipeline_info/trace.tsv" <<'PY'
import csv,sys
rows=list(csv.DictReader(open(sys.argv[1]),delimiter='\t'))
assert sum(r['status']=='COMPLETED' for r in rows)==1,rows
assert all(r['status'] in ('CACHED','COMPLETED') for r in rows),rows
assert sum(r['status']=='CACHED' for r in rows)==len(rows)-1,rows
print('PASS unchanged checkpoint workflow resume: only validation reruns')
PY
# Invalid checkpoint stage and already complete family must fail before science.
for mode in wrong-stage completed-family; do
 bad=("${common[@]}" -work-dir "$run_dir/rejected-$mode-work" --input_bundle "$run_dir/full/power/state" --outdir "$run_dir/rejected-$mode")
 if [[ "$mode" == wrong-stage ]]; then bad+=(--checkpoint_stage qc --analyses discovery); else bad+=(--checkpoint_stage power --analyses power); fi
 if (cd "$run_dir" && nextflow "${bad[@]}") > "$run_dir/$mode.log" 2>&1; then echo 'Invalid checkpoint accepted' >&2;exit 1;fi
 if [[ "$mode" == wrong-stage ]]; then grep -q 'checkpoint_stage must match' "$run_dir/$mode.log"; else grep -q 'already completed in checkpoint' "$run_dir/$mode.log"; fi
 if [[ -d "$run_dir/rejected-$mode/discovery" || -d "$run_dir/rejected-$mode/power" ]]; then echo 'Failed checkpoint published science' >&2;exit 1;fi
done
printf 'PASS actual Nextflow checkpoint-stage/family failures publish no scientific stage\n'

source_snapshot "$run_dir/source-after.json"
python3 - "$run_dir/source-before.json" "$run_dir/source-after.json" <<'PY_SOURCE_CHECK'
import json,sys
assert json.load(open(sys.argv[1]))==json.load(open(sys.argv[2])), 'Tested source changed during workflow qualification'
print('PASS exact pipeline/harness/archive source hashes unchanged throughout actual workflow qualification')
PY_SOURCE_CHECK
