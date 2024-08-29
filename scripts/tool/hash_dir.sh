#!/usr/bin/env bash
set -euo pipefail
trap "echo Exited with error!" ERR

dir1="$(realpath "$1")"

tmpdir=$(mktemp -d)
cd $tmpdir
echo "Working directory: $tmpdir"
echo "Hashing: $dir1"

find "$dir1" -type f -exec md5sum {} \; | tee sums1.txt &
find_pid=$!
wait $find_pid

cat sums1.txt | awk '{print $1}' | sort > srt1.txt

sum1=$(md5sum srt1.txt | awk '{print $1}')

echo "Working directory: $tmpdir"
echo "Hashed: $dir1"
echo "Hash for $dir1: $sum1"
