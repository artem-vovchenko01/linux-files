#!/usr/bin/env bash
set -euo pipefail

repo_root=$(git rev-parse --show-toplevel)
hooks_dir="$repo_root/.git/hooks"

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

mkdir -p "$hooks_dir"

for hook in "$script_dir"/*; do
  name=$(basename "$hook")
  case "$name" in
    install-hooks.sh|*.md|*.txt) continue ;;
  esac
  ln -sfv "$hook" "$hooks_dir/$name"
  chmod +x "$hook"
done
