#!/bin/bash

CONFIG_FILE=config.sh
SERVER=
USERTOKEN=

# dependency
DEPS=(atq animetick)
NG=0
for c in $DEPS; do
    if which $c >/dev/null; then
        true
    else
        NG=1
        echo "Not found: ${c}"
    fi
done
if [ $NG -eq 1 ]; then
    exit 1
fi

# config
if [ ! -f $CONFIG_FILE ]; then
    echo "No found $CONFIG_FILE"
    exit 1
fi

source $CONFIG_FILE

if [ -z "$SERVER" ]; then
    echo "No definition SERVER in $CONFIG_FILE"
    exit 1
fi

if [ -z "$USERTOKEN" ]; then
    echo "No definition USERTOKEN in $CONFIG_FILE"
    exit 1
fi

# args
USER=${1:-cympfh}
echo "Notification to @${USER}"

skip() {
    echo skipped
    false
}

report() {
    URL="https://${SERVER}/api/v1/statuses"
    MSG=$(html-encode "$1")
    echo $URL
    echo $MSG
    curl -s -XPOST \
        -H "Authorization: Bearer ${USERTOKEN}" \
        "$URL" \
        -d "visibility=unlisted&status=$MSG"
}

animetry() {
    animetick | ruby -p -e '
    require "time"
    a, b, *c = $_.split(" ")
    $_ = "#{Time.parse(a + " "  + b).to_i} #{c.join " "}\n"' |
    while read line; do
        anime_title=$(echo $line | sed 's/^[^ ]* //g')
        echo "Scheduled: $anime_title"
        time_before_5min=$(( $(echo $line | sed 's/ .*//g') - 300 ))
        atq $time_before_5min echo && report "$anime_title 5分前" || skip "$anime_title"
        time_before_1min=$(( $(echo $line | sed 's/ .*//g') - 60 ))
        atq $time_before_1min echo && report "$anime_title 1分前" || skip "$anime_title"
        if [ $? -eq 0 ]; then
            break
        fi
    done
}

while :; do
    animetry
    sleep 1m
done
