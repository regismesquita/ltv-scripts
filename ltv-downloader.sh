#!/bin/sh

#
# ltv-downloader.sh
#
# Baixa legendas do site legendas.tv.
# Mais informações no arquivo README
#

USER="$1"
PASSWORD="$2"
URL="$3&c=1"
DIRECTORY="$4"

COOKIEFILE=`mktemp /tmp/cookie-XXXXXXXXX`
SUBTITLE_DIR=`mktemp -d /tmp/subdir-XXXXXXXXX`
SUBTITLE_FILE=`mktemp $SUBTITLE_DIR/subtitle-XXXXXXXXX`

curl --silent --show-error --data "txtLogin=${USER}&txtSenha=${PASSWORD}" http://legendas.tv/login_verificar.php --cookie-jar $COOKIEFILE >> /dev/null
curl --silent --show-error --cookie $COOKIEFILE --location "$URL" -o "$SUBTITLE_FILE" >> /dev/null

echo Legenda baixada para o arquivo $SUBTITLE_FILE. Tentando descomprimir...

FORMAT=`file -b $SUBTITLE_FILE | awk '{ print $1 }'`

if [ "$FORMAT" == "RAR" ]; then
    echo "Formato detectado: RAR. Tentando descomprimir com unrar..."
    unrar x -inul -o+ "$SUBTITLE_FILE" "$DIRECTORY"
    if [ $? == 0 ]; then
        echo "Legendas descomprimidas para $DIRECTORY!"
        rm "$SUBTITLE_FILE"
    else   
        echo "Erro ao tentar descomprimir o arquivo $SUBTITLE_FILE"
    fi

elif [ "$FORMAT" == "zip" ]; then
    echo "Formato detectado: ZIP. Tentando descomprimir com unzip..."
    unzip -q -o "$SUBTITLE_FILE" -d "$DIRECTORY"
    if [ $? == 0 ]; then
      echo "Legendas descomprimidas para $DIRECTORY!"
      rm "$SUBTITLE_FILE"
    else
      echo "Erro ao tentar descomprimir o arquivo $SUBTITLE_FILE"
    fi
fi


