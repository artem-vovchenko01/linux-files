#!/usr/bin/env bash
dir1=$1
dir2=$2
echo "Comparing $dir1 to $dir2"

find $dir1 -type f -exec md5sum {} \; | tee sums1.txt &
find $dir2 -type f -exec md5sum {} \; | tee sums2.txt &

wait
wait

cat sums1.txt | awk '{print $1}' | sort > srt1.txt
cat sums2.txt | awk '{print $1}' | sort > srt2.txt

sum1=$(md5sum srt1.txt | awk '{print $1}')
sum2=$(md5sum srt2.txt | awk '{print $1}')

echo "Hash for $dir1: $sum1"
echo "Hash for $dir2: $sum2"

rm -v sums1.txt sums2.txt srt1.txt srt2.txt

if [ "$sum1" == "$sum2" ]; then
	echo Directory contents ARE identical
	else
	echo Directory contents ARE NOT identical
fi
