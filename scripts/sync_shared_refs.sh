#!/usr/bin/env bash
set -euo pipefail

# Sync every skill's canonical references from shared/<skill>/references/
# into each runtime adapter's references/. Generic over skills and runtimes.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
shared_root="$repo_root/shared"
runtimes=(claude codex)

if [[ ! -d "$shared_root" ]]; then
  echo "missing shared root: $shared_root" >&2
  exit 1
fi

shopt -s nullglob
synced_any=0
for shared_dir in "$shared_root"/*/references; do
  skill_name="$(basename "$(dirname "$shared_dir")")"
  for runtime in "${runtimes[@]}"; do
    target_dir="$repo_root/$runtime/skills/$skill_name/references"
    mkdir -p "$target_dir"
    # Clear the target contents (keep the dir itself) and mirror everything
    # under shared/<skill>/references/ — any file type, any subdirectory.
    find "$target_dir" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
    cp -R "$shared_dir/." "$target_dir/"
  done
  echo "synced: $skill_name -> ${runtimes[*]}"
  synced_any=1
done

if [[ "$synced_any" -eq 0 ]]; then
  echo "no skills found under $shared_root" >&2
  exit 1
fi