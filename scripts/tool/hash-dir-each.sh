#!/usr/bin/env bash
set -euo pipefail
for dir in $(ls -d */); do
	hash_dir.sh "${dir%/}" 2>&1 | tail -n3
done
