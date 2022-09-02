#!/bin/sh
# jq and ripgrep needed
subscriptions=$(cat $1 | jq '.[]' | jq '.snippet.title,.snippet.resourceId.channelId' | rg --multiline --no-filename -e '"(.*?)"\n"(.*?)"\n' -r '{
    "service_id": 0,
    "url": "https://www.youtube.com/channel/$2",
    "name": "$1"
},')

json="{
\"app_version\": \"0.20.2\",
\"app_version_int\": 956,
\"subscriptions\": [
${subscriptions::-1}
]
}"

echo "$json" > $2

