f_convert() {
  local LINK="$1"
  local DIR="$2"
  mkdir "$DIR"
  cd "$DIR"
  youtube-dl -x "$LINK"
  local FILE=$(echo *.opus)
  local N_FILE="${FILE%-*}.opus"
  mv "$FILE" "$N_FILE"
  ffmpeg -i "$N_FILE" "${N_FILE%.*}.mp3"
  rm "$N_FILE"
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

