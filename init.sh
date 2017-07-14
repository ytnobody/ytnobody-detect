#!/bin/sh
if [ ! -e /bin/cpm ] ; then
    curl -sL --compressed https://git.io/cpm > cpm
    chmod +x cpm
    mv cpm /bin/cpm
fi

cpm install .

local/bin/morbo -l http://*:$PORT "api.psgi"