#!/usr/bin/env bash

FIRST=$(ls | grep -P '^\d' | head -n1 | awk -F ' ' '{print $1}')
LAST=$(ls | grep -P '^\d' | tail -n1 | awk -F ' ' '{print $1}')
MAX=$(echo $FIRST | tr 0-9 9)
ACTUAL=$(ls | grep -P '^\d')

echo Checking the range from $FIRST to $LAST

POSSIBLE=$(seq -w $FIRST $LAST)

for n in $POSSIBLE; do
  if ! ls | grep -q "^$n"; then
    echo $n is absent!
  fi
done
