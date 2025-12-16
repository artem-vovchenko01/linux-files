IMG=$1
TEMP=${IMG}_temp

set -eux
convert $IMG -rotate 90 $TEMP

rm $IMG
mv $TEMP $IMG
