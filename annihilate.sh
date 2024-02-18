#!/bin/bash

source requirements.sh

color
heading "Annihilate" "Files"
install "touch" "touch"

heading "Annihilate" "Files"

if [ $# -eq 0 ]; then
    echo -e "${c[33]}Please enter the directory address: ${c[0]}"
    read -r directory
elif [ $# -eq 1 ]; then
    directory="$1"
else
    echo -e "${c[31]}Too any arguements provided...${c[0]}"
    exit 1
fi

annihilate() {
    find "$1" -type f | while read -r file; do
        rm "$file"
        touch "$file"
    done
}

annihilate "${directory}" &&
    echo -e "${directory} annihilated!!!"
