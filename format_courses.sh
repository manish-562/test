#!/bin/bash

source requirements.sh

color
heading "Format" "Courses"
install "Unzip" "unzip"

heading "Format" "Courses"

if [ $# -eq 0 ]; then
    echo -e "${c[33]}Please enter the file address: ${c[0]}"
    read -r file
    echo -ne "${c[33]}Enter the language of the course: ${c[0]}" && read -r language
    echo -ne "${c[33]}Cover timestamp for intro: ${c[0]}" && read -r ti
    echo -ne "${c[33]}Cover timestamp for others: ${c[0]}" && read -r to
elif [ $# -eq 1 ]; then
    file="$1"
    language="en"
    ti=05
    to=01
else
    echo -e "${c[31]}Too any arguements provided...${c[0]}"
    exit 1
fi

heading "Format" "Courses"

failed() {
    echo -e "${c[31]}$1 Failed!!!${c[0]}"
    exit 1
}

mkdir -p "/sdcard/Programming Videos"
file=${file//'/storage/emulated/0/'/'/sdcard/'}
loading "Extracting the zip file..." &
unzip "$file" -d "/sdcard/Programming Videos" >/dev/null 2>&1 || failed "unziping"
end_loading "Extracting the zip file..."
cd "/sdcard/Programming Videos" || exit
heading "Format" "Courses"

for dir_0 in */; do
    if [ -d "$dir_0" ]; then
        newdir=${dir_0//'[FreeCoursesOnline.Me] '/}
        newdir=${newdir//' [FCS]'/}
        newdir=${newdir//'Code With Mosh - '/}
        newdir=${newdir//'The Ultimate '/}
        newdir=${newdir//'Ultimate '/}
        newdir=${newdir%' ['*}
        newdir=${newdir%'['*}
        newdir=${newdir%']'*}
        [ "$dir_0" != "${newdir}" ] && mv "$dir_0" "$newdir"
        newdir=${newdir%'/'*}
        if [[ "$dir_0" == *"["*"]"* ]]; then
            course="$newdir"
        fi
    fi
done

course="/sdcard/Programming Videos/${course}"

prefix() {
    for file in *; do
        if [[ "$file" == [0-9]'- '* ]]; then
            mv "$file" "0${file}"
        fi
    done
    [ -z "$level" ] && level=0
    [ "$level" -eq 0 ] && prefix=""
    [ "$level" -eq 1 ] && prefix="${prefix_1}."
    [ "$level" -eq 2 ] && prefix="${prefix_1}.${prefix_2}."
}

encode() {
    for file in *.mp4; do
        if [ -f "$file" ]; then
            input=${file%.*}
            output="${course}/${prefix}${input}"
            title="${input#*[0-9]'- '}"
            desc="$(pwd)"
            desc="${desc##*'/'}"
            desc="${desc#*'- '}"
            if [[ "$file" == "01- "* ]]; then
                frame="00:00:${ti}"
            else
                frame="00:00:${to}"
            fi
            ffmpeg -y -i "${input}.mp4" \
                -map 0:v:0 \
                -map_metadata -1 -map_metadata:s -1 -map_metadata:g -1 -map_chapters -1 -map_chapters:s -1 -map_chapters:g -1 \
                -ss "$frame" -vframes 1 \
                "${input}.jpg" >/dev/null 2>&1 ||
                failed Conversion
            ffmpeg -y -i "${input}.mp4" \
                -map 0:s? \
                -map_metadata -1 -map_metadata:s -1 -map_metadata:g -1 -map_chapters -1 -map_chapters:s -1 -map_chapters:g -1 \
                "${input}.en.srt" >/dev/null 2>&1 ||
                no_embeded_subs="${no_embeded_subs}${output##*'/'}\n"
            sub_lang=$(ls "${input}"*".srt" 2>/dev/null)
            if [ -n "$sub_lang" ]; then
                sub_lang=${sub_lang%.*}
                sub_lang=${sub_lang##*.}
                ffmpeg -y -i "${input}.mp4" -i "${input}.en.srt" \
                    -map 0:v:0 -map 0:a:0 -map 1:s \
                    -map_metadata -1 -map_metadata:s -1 -map_metadata:g -1 -map_chapters -1 -map_chapters:s -1 -map_chapters:g -1 \
                    -metadata title="${title}" -metadata comment="${desc}" -metadata:s:a:0 language="${language}" -metadata:s:s:0 language="${sub_lang}" \
                    -c copy \
                    -attach "${input}.jpg" -metadata:s:t filename="$title" -metadata:s:t mimetype=image/jpeg \
                    "${output}.mkv" >/dev/null 2>&1 ||
                    failed Conversion
                rm "${input}.en.srt"
            else
                ffmpeg -y -i "${input}.mp4" \
                    -map 0:v:0 -map 0:a:0 \
                    -map_metadata -1 -map_metadata:s -1 -map_metadata:g -1 -map_chapters -1 -map_chapters:s -1 -map_chapters:g -1 \
                    -metadata title="${title}" -metadata comment="${desc}" -metadata:s:a:0 language="${language}" \
                    -c copy \
                    -attach "${input}.jpg" -metadata:s:t filename="$title" -metadata:s:t mimetype=image/jpeg \
                    "${output}.mkv" >/dev/null 2>&1 ||
                    failed Conversion
                no_subs="${no_subs}${output##*'/'}\n"
            fi
            rm "${input}.mp4" "${input}.jpg"
            echo -e "${c[34]}${input}.mp4${c[33]} > ${c[32]}${output##*'/'}.mkv${c[0]}"
        fi
    done
}

rescue() {
    for file in *; do
        if [ -f "$file" ] && [[ "$file" != *.mkv ]]; then
            if [[ "$file" == *code* ]] && [[ "$file" == *.zip ]]; then
                output="code.zip"
            else
                output="$file"
            fi
            mv "$file" "${course}/${prefix}${output}"
            echo -e "${c[34]}${file}${c[33]} > ${c[32]}${prefix}${output}${c[0]}"
        fi
    done
}

cd "$course" || exit
rm -rf -- *"Websites you may like"* *.url
prefix
rescue

prefix_1=1
for dir_1 in */; do
    if [ -d "$dir_1" ]; then
        cd "$dir_1" || exit
        level=1
        prefix
        encode
        rescue
        prefix_2=1
        for dir_2 in */; do
            if [ -d "$dir_2" ]; then
                cd "$dir_2" || exit
                level=2
                prefix
                encode
                rescue
                ((prefix_2++))
                cd .. || exit
                rmdir "$dir_2"
            fi
        done
        cd .. || exit
        rmdir "$dir_1"
        ((prefix_1++))
    fi
done

echo -e "${c[31]}The following files have no embedded subs.${c[0]}"
echo -e "${c[36]}${no_embeded_subs}${c[0]}"

echo -e "${c[31]}The following files will have no subs.${c[0]}"
echo -e "${c[36]}${no_subs}${c[0]}"
cd ~ || exit
