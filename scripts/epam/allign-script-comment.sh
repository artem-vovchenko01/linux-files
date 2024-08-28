TOTAL_SIZE=50
HEADER=$1
DASH='-'
IS_COMMENT=1
IS_COMMENT=0

print_stats() {
	echo "Total: $TOTAL_SIZE"
	echo "Header: $HEADER_SIZE"
	echo "Dashes: $((DASH_SIZE * 2)) = $DASH_SIZE * 2"
}

print_comment() {
	HEADER_SIZE=$(echo $HEADER | wc -c)
	DASH_SIZE=$(( (TOTAL_SIZE - HEADER_SIZE - 6) / 2))
	# print_stats

	if [[ $IS_COMMENT == 1 ]]; then
		echo -n "# "
	else
		echo -n ""
	fi

	for ((i=0; i < $DASH_SIZE; i++)); do
		echo -n "$DASH"
	done

	echo -n ' [ '
	echo -n $HEADER
	echo -n ' ] '

	for ((i=0; i < $DASH_SIZE; i++)); do
		echo -n "$DASH"
	done

	[[ $((HEADER_SIZE % 2)) -eq 1 ]] && echo -n "$DASH"

	echo
}

print_comment

print_example() {
	EXAMPLE="This is example phrase"
	MAX=$(echo $EXAMPLE | wc -c)
	for ((j=1; j < $MAX; j++)); do
		HEADER=$(echo $EXAMPLE | head -c $j)
		print_comment
	done
}

# print_example
