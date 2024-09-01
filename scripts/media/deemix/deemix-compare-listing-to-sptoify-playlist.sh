set -e

WORKDIR=$(mktemp -d)

ls | grep -P '^\d' | sed 's/.* - //; s/.mp3//' > $WORKDIR/1

cd $WORKDIR

# here my own script is used
spotify-list-playlist.py $1 > 2

cat 1 2 > 3
cat 3 | sort | uniq -u
echo These are songs that occur only once when playlist from Spotify and from current folder are combined
