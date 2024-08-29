#!/usr/bin/env bash
dir1=$1
echo "Hashing $dir1"

find $dir1 -type f -exec md5sum {} \; | tee sums1.txt &

wait

cat sums1.txt | awk '{print $1}' | sort > srt1.txt

sum1=$(md5sum srt1.txt | awk '{print $1}')

echo "Hash for $dir1: $sum1"

rm -v sums1.txt srt1.txt 

