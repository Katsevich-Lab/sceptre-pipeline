#!/usr/bin/env bash
set -euo pipefail
repo=$(pwd)
root=${1:?Usage: tests/run-launcher.sh NEW_ROOT (SCEPTRE_CONTAINER_IMAGE required)}
image=${SCEPTRE_CONTAINER_IMAGE:?Set exact qualified image digest}
engine=${SCEPTRE_CONTAINER_ENGINE:-docker}
mkdir -p "$root"
root=$(cd "$root" && pwd)
run_r() {
 if [[ "$engine" == docker ]]; then docker run --rm -v "$repo:$repo" -v "$root:$root" -w "$repo" "$image" Rscript --vanilla "$@"
 else apptainer exec --cleanenv --bind "$repo:$repo" --bind "$root:$root" --pwd "$repo" "$image" Rscript --vanilla "$@"; fi
}
run_r tests/make-launcher-input.R "$root/raw"
args=(--data-root "$root/raw" --input-json "$root/raw/input.json" --analysis-json "$root/raw/analysis.json" --run-dir "$root/run" --engine "$engine" --container-image "$image" --profiles "test,$engine")
if [[ "$engine" == apptainer ]]; then
 checksum=$(python3 - "$image" <<'PY'
import hashlib,sys
h=hashlib.sha256()
with open(sys.argv[1],'rb') as f:
 for chunk in iter(lambda:f.read(1048576),b''):h.update(chunk)
print(h.hexdigest())
PY
)
 args+=(--container-image-sha256 "$checksum")
fi
python3 bin/sceptre-pipeline "${args[@]}" -- --execution_mode distributed --n_work_units 3
# Compatibility aliases for the existing independent public-R oracle only.
run_r -e 'p<-commandArgs(TRUE)[1]; stopifnot(file.copy(file.path(p,"analysis_config.rds"),file.path(p,"config.rds")),file.copy(file.path(p,"environment_lock.rds"),file.path(p,"lock.rds")))' "$root/run/prepared"
run_r tests/ci/compare-workflow.R "$root/run/prepared" "$root/run/results" 271828 analysis discovery "$root/run/prepared/backing"
python3 bin/sceptre-pipeline "${args[@]}" --resume -- --execution_mode distributed --n_work_units 3
python3 - "$root/run/results/pipeline_info/trace.tsv" <<'PY'
import csv,sys
rows=list(csv.DictReader(open(sys.argv[1]),delimiter='\t'))
assert sum(r['status']=='COMPLETED' for r in rows)==1,rows
assert sum(r['status']=='CACHED' for r in rows)==len(rows)-1,rows
print('PASS one-command rawJSON nativeHDF5 CRT launcher/directR comparison and unchanged resume; no host R dependency')
PY
# A nested source change must reject before Nextflow, preserving original results.
cp "$root/raw/guide.rds" "$root/guide-original.rds"
printf 'changed source' > "$root/raw/guide.rds"
if python3 bin/sceptre-pipeline "${args[@]}" --resume -- --execution_mode distributed --n_work_units 3 > "$root/rejected-source.log" 2>&1; then echo 'Changed nested raw source resumed' >&2;exit 1;fi
grep -q 'Prepared project source changed' "$root/rejected-source.log"
cp "$root/guide-original.rds" "$root/raw/guide.rds"
if python3 bin/sceptre-pipeline "${args[@]}" --resume -- --execution_mode reference > "$root/rejected-settings.log" 2>&1; then echo 'Changed settings resumed' >&2;exit 1;fi
grep -q 'Launcher source/settings/image differ' "$root/rejected-settings.log"
printf 'PASS one-command launcher source/settings guards reject before scientific submission\n'
