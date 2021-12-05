f_convert() {
  local LINK="$1"
  local DIR="$2"
  mkdir "$DIR"
  cd "$DIR"
  youtube-dl -f "bestaudio/best" -o "%(title)s.%(ext)s" --extract-audio --audio-quality 0 --audio-format mp3 "$LINK"
  mv *.mp3 ..
  cd ..
  rmdir "$DIR"
}

while read line; do
	NAME="${line##*/}"
	f_convert "$line" "$NAME" > "${NAME}.txt" 2>&1 &
done

wait

echo "All downloads finished!"

read -p "Remove logs?" ANSWER
if [[ ANSWER = "y" || ANSWER = "Y" ]]; then
	rm *.txt
fi

