#!/usr/bin/env bash
set -euo pipefail
repo=$(pwd)
root=${1:?Usage: tests/run-launcher.sh NEW_ROOT (SCEPTRE_CONTAINER_IMAGE required)}
image=${SCEPTRE_CONTAINER_IMAGE:?Set exact qualified image digest}
engine=${SCEPTRE_CONTAINER_ENGINE:-docker}
mkdir -p "$root"
root=$(cd "$root" && pwd)
run_r() {
 if [[ "$engine" == docker ]]; then docker run --rm --user "$(id -u):$(id -g)" -e HOME=/tmp -e R_LIBS_USER=/nonexistent -v "$repo:$repo" -v "$root:$root" -w "$repo" "$image" Rscript --vanilla "$@"
 else apptainer exec --containall --cleanenv --bind "$repo:$repo" --bind "$root:$root" --pwd "$repo" "$image" Rscript --vanilla "$@"; fi
}
if [[ "$engine" == docker ]]; then python3 tests/ci/check-docker-caller.py "$root/docker-linux-caller.json"; fi
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
# A successful workflow must leave raw, prepared and published files usable by
# its caller on native Linux, not merely readable through a Docker Desktop mount.
python3 - "$root" <<'PY_OWNER'
import json,os,pathlib,sys
root=pathlib.Path(sys.argv[1]);receipt={'host_uid':os.getuid(),'host_gid':os.getgid(),'platform':sys.platform,'native_linux_gid_asserted':sys.platform.startswith('linux'),'gid_mapping_limit':None if sys.platform.startswith('linux') else 'Docker Desktop bind mounts may project GID differently; native Linux named-volume proof remains strict.','trees':{}}
for name in ('raw','run/prepared','run/work','run/results'):
 path=root/name
 entries=[path,*path.rglob('*')]
 for item in entries:
  if item.is_symlink():continue
  assert item.stat().st_uid==os.getuid(),(str(item),item.stat().st_uid,os.getuid())
  if sys.platform.startswith('linux'):
   assert item.stat().st_gid==os.getgid(),(str(item),item.stat().st_gid,os.getgid())
  assert os.access(item,os.R_OK | (os.W_OK if item.is_dir() or item.is_file() else 0)),str(item)
 probe=path/'caller-ownership-probe.txt'
 probe.write_text('caller can create/edit/delete')
 probe.write_text('caller can edit')
 probe.unlink()
 receipt['trees'][name]={'entries':len(entries),'all_caller_uid':True,'observed_gids':sorted({item.stat().st_gid for item in entries if not item.is_symlink()}),'caller_create_edit_delete':True}
(root/'caller-ownership.json').write_text(json.dumps(receipt,indent=2)+'\n')
print('PASS raw/prepared/published ownership and caller create/edit/delete')
PY_OWNER
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
# Generated launch parameters cannot change the request during unchanged resume.
cp "$root/run/prepared/params.json" "$root/params-original.json"
for field in seed analyses input_bundle; do
 python3 - "$root/run/prepared/params.json" "$field" <<'PY_PARAMS'
import json,sys
path,field=sys.argv[1:]
params=json.load(open(path))
params[field]={'seed':999,'analyses':'calibration','input_bundle':'/different/screen'}[field]
with open(path,'w') as handle:json.dump(params,handle)
PY_PARAMS
 if python3 bin/sceptre-pipeline "${args[@]}" --resume -- --execution_mode distributed --n_work_units 3 > "$root/rejected-params-$field.log" 2>&1; then echo 'Changed prepared parameters resumed' >&2;exit 1;fi
 grep -q 'Prepared launch parameters changed' "$root/rejected-params-$field.log"
 cp "$root/params-original.json" "$root/run/prepared/params.json"
done
# A nested source change must reject before Nextflow, preserving original results.
cp "$root/raw/guide.rds" "$root/guide-original.rds"
printf 'changed source' > "$root/raw/guide.rds"
if python3 bin/sceptre-pipeline "${args[@]}" --resume -- --execution_mode distributed --n_work_units 3 > "$root/rejected-source.log" 2>&1; then echo 'Changed nested raw source resumed' >&2;exit 1;fi
grep -q 'Prepared project source changed' "$root/rejected-source.log"
cp "$root/guide-original.rds" "$root/raw/guide.rds"
if python3 bin/sceptre-pipeline "${args[@]}" --resume -- --execution_mode reference > "$root/rejected-settings.log" 2>&1; then echo 'Changed settings resumed' >&2;exit 1;fi
grep -q 'Launcher source/settings/image differ' "$root/rejected-settings.log"
printf 'PASS one-command launcher source/settings guards reject before scientific submission\n'
