#!/usr/bin/env bash
set -Eeu

usage() {
  echo "Usage: $0 [--dry-run] <target-directory>" >&2
}

dry_run=false
target_dir=""
stage_dir=""
install_committed=false
created_files=()
created_stage_files=()
created_dirs=()

while (($# > 0)); do
  case "$1" in
    --dry-run) dry_run=true ;;
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

ensure_directory() {
  local directory="$1"
  local parent
  if [[ -L "$directory" ]]; then
    echo "Target directory is a symbolic link: $directory" >&2
    return 1
  fi
  if [[ -d "$directory" ]]; then return; fi
  if [[ -e "$directory" ]]; then
    echo "Target path is not a directory: $directory" >&2
    return 1
  fi
  parent="$(dirname "$directory")"
  ensure_directory "$parent"
  mkdir "$directory"
  created_dirs+=("$directory")
}

cleanup_install() {
  local exit_code=$?
  local i
  if ! $install_committed; then
    for ((i=${#created_files[@]} - 1; i >= 0; i--)); do
      if [[ -e "${created_files[$i]}" ]] && [[ "${created_files[$i]}" -ef "${created_stage_files[$i]}" ]]; then
        unlink "${created_files[$i]}"
      fi
    done
  fi
  if [[ -n "$stage_dir" && -d "$stage_dir" ]]; then
    rm -rf "$stage_dir"
  fi
  if ! $install_committed; then
    for ((i=${#created_dirs[@]} - 1; i >= 0; i--)); do
      rmdir "${created_dirs[$i]}" 2>/dev/null || true
    done
  fi
  return "$exit_code"
}

trap cleanup_install EXIT

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
asset_dir="$(cd "$script_dir/../assets/framework" && pwd)"
relative_files=(
  "core/MVI.ts"
  "core/MVIDeferred.ets"
  "core/MVICommonEffects.ets"
)

has_conflict=false
add_files=()
normalize_target_dir
assert_no_symlink_components "$target_dir"
for relative_path in "${relative_files[@]}"; do
  source_path="$asset_dir/$relative_path"
  target_path="$target_dir/$relative_path"
  if ! assert_no_symlink_components "$target_path"; then
    echo "CONFLICT $relative_path (path contains a symbolic link)" >&2
    has_conflict=true
  elif [[ -L "$target_path" ]]; then
    echo "CONFLICT $relative_path (symbolic link)" >&2
    has_conflict=true
  elif [[ ! -e "$target_path" ]]; then
    echo "ADD      $relative_path"
    add_files+=("$relative_path")
  elif [[ -f "$target_path" ]] && cmp -s "$source_path" "$target_path"; then
    echo "SAME     $relative_path"
  else
    echo "CONFLICT $relative_path" >&2
    has_conflict=true
  fi
done

if $has_conflict; then
  echo "Conflicts detected; no files were written" >&2
  exit 2
fi

if $dry_run; then
  echo "Dry run complete; no files were written"
  exit 0
fi

ensure_directory "$target_dir"
stage_dir="$(mktemp -d "$target_dir/.hmos-mvi-install.XXXXXX")"
if ((${#add_files[@]} > 0)); then
  for relative_path in "${add_files[@]}"; do
    source_path="$asset_dir/$relative_path"
    stage_path="$stage_dir/$relative_path"
    mkdir -p "$(dirname "$stage_path")"
    cp "$source_path" "$stage_path"
  done
fi

# Recheck after staging to catch files or links created between preflight and commit.
assert_no_symlink_components "$target_dir"
for relative_path in "${relative_files[@]}"; do
  target_path="$target_dir/$relative_path"
  if ! assert_no_symlink_components "$target_path"; then
    echo "Path contains a symbolic link before commit: $relative_path" >&2
    exit 2
  fi
  if [[ -L "$target_path" ]]; then
    echo "Symbolic link detected before commit: $relative_path" >&2
    exit 2
  fi
done

if ((${#add_files[@]} > 0)); then
  for relative_path in "${add_files[@]}"; do
    stage_path="$stage_dir/$relative_path"
    target_path="$target_dir/$relative_path"
    if [[ -e "$target_path" || -L "$target_path" ]]; then
      echo "Conflict detected before commit: $relative_path" >&2
      exit 2
    fi
    ensure_directory "$(dirname "$target_path")"
    assert_no_symlink_components "$(dirname "$target_path")"
    if ! ln "$stage_path" "$target_path"; then
      echo "Write failed; rolling back this installation: $relative_path" >&2
      exit 1
    fi
    created_files+=("$target_path")
    created_stage_files+=("$stage_path")
  done
fi

install_committed=true
echo "Installation complete: $target_dir"
