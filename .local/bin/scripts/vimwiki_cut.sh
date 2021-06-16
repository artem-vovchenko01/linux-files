if [ ! -f ./index.wiki ]; then
    echo No index.wiki found
    exit
fi

line_num=$1
line=$( sed -n ''${line_num}p'' index.wiki )

echo $line

