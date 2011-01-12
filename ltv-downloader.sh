#!/bin/sh

USER="$1"
PASSWORD="$2"
URL="$3&c=1"
DIRECTORY="$4"

COOKIEFILE=`mktemp /tmp/cookie-XXXXXXXXX`
SUBTITLE_DIR=`mktemp -d /tmp/subdir-XXXXXXXXX`
SUBTITLE_FILE=`mktemp $SUBTITLE_DIR/subtitle-XXXXXXXXX`

curl --silent --show-error --data "txtLogin=${USER}&txtSenha=${PASSWORD}" http://legendas.tv/login_verificar.php --cookie-jar $COOKIEFILE >> /dev/null
curl --silent --show-error --cookie $COOKIEFILE --location "$URL" -o "$SUBTITLE_FILE" >> /dev/null

echo Subtitle downloaded to $SUBTITLE_FILE. Trying to uncompress...

FORMAT=`file -b $SUBTITLE_FILE | awk '{ print $1 }'`

if [ "$FORMAT" == "RAR" ]; then
    echo "Uncompressing with unrar..."
    unrar x -inul -o+ "$SUBTITLE_FILE" "$DIRECTORY"
    if [ $? == 0 ]; then
        echo "Subtitles uncompressed to $DIRECTORY!"
        rm "$SUBTITLE_FILE"
    else   
        echo "Error trying to uncompress $SUBTITLE_FILE"
    fi

#
# TODO: ZIP files
elif [ "$FORMAT" == "ZIP" ]; then
    echo ZIP format not supported yet.
    echo Your subtitle is at $SUBTITLE_FILE
fi


