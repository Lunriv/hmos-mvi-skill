#!/usr/bin/env bash
set -u

usage() {
  echo "Usage: $0 <target-directory>" >&2
}

target_dir=""
while (($# > 0)); do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --*) echo "Unknown option: $1" >&2; usage; exit 64 ;;
    *)
      if [[ -n "$target_dir" ]]; then
        echo "Specify exactly one target directory" >&2
        usage
        exit 64
      fi
      target_dir="$1"
      ;;
  esac
  shift
done

if [[ -z "$target_dir" ]]; then
  usage
  exit 64
fi

if [[ "/$target_dir/" == *"/../"* ]]; then
  echo "Target directory must not contain a .. path segment" >&2
  exit 64
fi
if [[ "$target_dir" != /* ]]; then
  target_dir="$PWD/$target_dir"
fi

assert_no_symlink_components() {
  local path="$1"
  local current=""
  local component
  local components=()
  IFS='/' read -r -a components <<< "${path#/}"
  for component in "${components[@]}"; do
    [[ -z "$component" || "$component" == "." ]] && continue
    current="$current/$component"
    if [[ -L "$current" ]]; then
      echo "Target path contains a symbolic link: $current" >&2
      return 1
    fi
  done
}

normalize_target_dir() {
  local cursor="$target_dir"
  local suffix=""
  if [[ -L "$cursor" ]]; then
    echo "Target directory must not be a symbolic link: $cursor" >&2
    return 1
  fi
  while [[ ! -e "$cursor" ]]; do
    suffix="/$(basename "$cursor")$suffix"
    cursor="$(dirname "$cursor")"
  done
  if [[ ! -d "$cursor" ]]; then
    echo "Existing target ancestor is not a directory: $cursor" >&2
    return 1
  fi
  target_dir="$(cd "$cursor" && pwd -P)$suffix"
}

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
asset_dir="$(cd "$script_dir/../assets/framework" && pwd)"
core_files=(
  "core/MVI.ts"
  "core/MVIDeferred.ets"
  "core/MVICommonEffects.ets"
)
has_error=false
normalize_target_dir
assert_no_symlink_components "$target_dir"

verify_file() {
  local relative_path="$1"
  local target_path="$target_dir/$relative_path"
  if ! assert_no_symlink_components "$target_path"; then
    echo "SYMLINK  $relative_path" >&2
    has_error=true
    return
  fi
  if [[ -L "$target_path" ]]; then
    echo "SYMLINK  $relative_path" >&2
    has_error=true
    return
  fi
  if [[ ! -f "$target_path" ]]; then
    echo "MISSING  $relative_path" >&2
    has_error=true
    return
  fi
  if ! cmp -s "$asset_dir/$relative_path" "$target_path"; then
    echo "CHANGED  $relative_path" >&2
    has_error=true
    return
  fi
  if grep -n -E 'TODO|PLACEHOLDER|\[TODO' "$target_path" >/dev/null; then
    echo "TEMPLATE $relative_path" >&2
    has_error=true
    return
  fi
  echo "OK       $relative_path"
}

for relative_path in "${core_files[@]}"; do
  verify_file "$relative_path"
done

if $has_error; then
  exit 1
fi

echo "Verification passed: $target_dir"
