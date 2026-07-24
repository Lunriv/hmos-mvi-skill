#!/usr/bin/env bash
set -u

usage() {
  echo "Usage: $0 <newly-generated-feature-directory>" >&2
}

feature_dir="${1:-}"
if [[ -z "$feature_dir" || $# -ne 1 ]]; then
  usage
  exit 64
fi
if [[ ! -d "$feature_dir" ]]; then
  echo "Feature directory does not exist: $feature_dir" >&2
  exit 64
fi

has_warning=false
warn() {
  echo "WARN     $1" >&2
  has_warning=true
}

while IFS= read -r file_path; do
  warn "Generic feature file name: $file_path"
done < <(find "$feature_dir" -type f \( -name '*Mvi.ets' -o -name 'Model.ets' -o -name 'VM.ets' -o -name 'State.ets' \) -print)

for layer_name in state intent effect; do
  if [[ ! -d "$feature_dir/$layer_name" ]]; then
    warn "Missing $layer_name/ directory"
  fi
done

if ! find "$feature_dir" -type f -name '*State.ets' -print -quit | grep -q .; then
  warn 'No concrete *State.ets file found'
fi
if ! find "$feature_dir" -type f -name '*Intent.ets' -print -quit | grep -q .; then
  warn 'No concrete *Intent.ets file found'
fi
if ! find "$feature_dir" -type f -name '*Effect.ets' -print -quit | grep -q .; then
  warn 'No concrete *Effect.ets file found'
fi

if $has_warning; then
  echo 'Audit complete: warnings only; no files were modified and build results are unaffected.' >&2
else
  echo 'Audit complete: the newly generated feature directory follows MVI naming guidance.'
fi
