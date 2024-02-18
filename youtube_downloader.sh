#!/bin/bash

source requirements.sh

color
heading "YouTube" "Downloader"
install "FFmpeg" "jq" "Python" "Python-pip" "yt-dlp" "ffmpeg" "jq" "python3" "python3-pip" "yt-dlp"

heading "YouTube" "Downloader"

if [ $# -eq 0 ]; then
    echo -e "${c[33]}Please enter the url: ${c[0]}"
    read -r url
elif [ $# -eq 1 ]; then
    url="$1"
elif [ $# -eq 2 ]; then
    url="$1"
    audio_format="$2"
elif [ $# -eq 3 ]; then
    url="$1"
    video_format="$2"
    audio_format="$3"
else
    echo -e "${c[31]}Too any arguements provided...${c[0]}"
    exit 1
fi

heading "YouTube" "Downloader"
extract_info() {
    media_info=$(yt-dlp --no-warnings -j --playlist-items "$index" "$url")
    id=$(echo "$media_info" | jq -r '.id')
    webpage_url=$(echo "$media_info" | jq -r '.webpage_url')
    playlist_title=$(echo "$media_info" | jq -r '.playlist_title')
    playlist_id=$(echo "$media_info" | jq -r '.playlist_id')
    playlist_count=$(echo "$media_info" | jq -r '.playlist_count')
    playlist_index=$(echo "$media_info" | jq -r '.playlist_index')
    channel=$(echo "$media_info" | jq -r '.channel')
    channel_id=$(echo "$media_info" | jq -r '.channel_id')
    track=$(echo "$media_info" | jq -r '.track')
    artist=$(echo "$media_info" | jq -r '.artist')
    album=$(echo "$media_info" | jq -r '.album')
    release_year=$(echo "$media_info" | jq -r '.release_year')
    artist="${artist%%,*}"
    track_number="${playlist_index}/${playlist_count}"
}
index=1
loading "Extracting media info..." &
extract_info

if [ -n "$id" ]; then
    if [ "$track" = "null" ] && [ "$playlist_id" = "null" ]; then
        type="video"
        url="$webpage_url"
        temp_dir="/sdcard/YouTube Videos/.cache/${id}"
        file=$(yt-dlp --no-warnings --print filename -o "%(title)s.mkv" "$url")
        final_dir="/sdcard/YouTube Videos"
    elif [ "$playlist_id" = "null" ]; then
        type="music"
        url="$webpage_url"
        temp_dir="/sdcard/YouTube Videos/.cache/${id}"
        file="${artist} - ${track}.mp3"
        final_dir="/sdcard/Music"
    elif [ "$playlist_id" = "$channel_id" ]; then
        type="channel"
        url="https://youtube.com/playlist?list=UULF${channel_id:2}"
        extract_info
        temp_dir="/sdcard/YouTube Videos/.cache/${channel_id}"
        final_dir="/sdcard/YouTube Videos/${channel}"
    elif [ "$track" != "null" ] && [ "$playlist_id" != "null" ]; then
        type="album"
        url="https://youtube.com/playlist?list=${playlist_id}"
        temp_dir="/sdcard/YouTube Videos/.cache/${playlist_id}"
        is_playlist=0
        [[ $playlist_title == "Album - "* ]] || {
            album="${playlist_title}"
            is_playlist=1
        }
        final_dir="/sdcard/Music/${album}"
    elif [[ "$playlist_id" == PL* ]]; then
        type="playlist"
        url="https://youtube.com/playlist?list=${playlist_id}"
        temp_dir="/sdcard/YouTube Videos/.cache/${playlist_id}"
        final_dir="/sdcard/YouTube Videos/${playlist_title}"
    fi
else
    heading "YouTube" "Downloader"
    end_loading "Extracting media info..."
    echo -e "${c[31]}Invalid url...${c[0]}"
    exit 1
fi
end_loading "Extracting media info..."

heading "YouTube" "Downloader"
single=0
if [ -n "$file" ]; then
    single=1
    if [ -f "${final_dir}/${file}" ]; then
        echo -e "${c[31]}The ${type} already exists!!!${c[0]}"
        echo -ne "${c[33]}Download anyway?(Y/n): ${c[0]}" && read -r overwrite
        [ "$overwrite" = "Y" ] || [ "$overwrite" = "y" ] || {
            echo -e "${c[31]}Terminating the script${c[0]}"
            sleep 1
            exit 0
        }
    fi
elif [ -d "$final_dir" ]; then
    echo -e "${c[31]}The ${type} folder already exists!!!${c[0]}"
    echo -ne "${c[33]}Overwrite/Skip?(Y/n): ${c[0]}" && read -r overwrite
fi
check() {
    if [ -f "${final_dir}/${file}" ]; then
        echo -e "${c[33]}${file%.*} already exists!${c[0]}"
        [ "$overwrite" = "Y" ] || [ "$overwrite" = "y" ] || {
            echo -e "${c[31]}Skipping ${file%.*}...${c[0]}"
            sleep 1
            skip=1
        }
    fi
}

failed() {
    echo -e "${c[31]}$1 Failed!!!${c[0]}"
    exit 1
}

if [ $# -eq 0 ]; then
    heading "YouTube" "Downloader"
    echo -e "${c[32]}Finding available formats...${c[0]}"
    yt-dlp --no-warnings --print formats_table --playlist-items 1 "$url"
    [ "$type" = music ] || [ "$type" = album ] || read -rp "Choose video format: " video_format
    [[ "$video_format" == *p ]] || read -rp "Choose audio format: " audio_format
fi

[ -z "$video_format" ] && video_format=136
[ -z "$audio_format" ] && audio_format=140
[ "$video_format" = "1080p" ] || [ "$video_format" = 137 ] && video_format='137/399/136/135/134/133'
[ "$video_format" = "720p" ] || [ "$video_format" = 136 ] && video_format='136/135/134/133'
[ "$video_format" = "480p" ] || [ "$video_format" = 135 ] && video_format='135/134/133'
[ "$video_format" = "360p" ] || [ "$video_format" = 134 ] && video_format='134/133'
[ "$video_format" = "240p" ] && video_format='133'
[ "$audio_format" = "140" ] && audio_format='140/139'

heading "YouTube" "Downloader"

mkdir -p "${temp_dir}"
cd "${temp_dir}" || exit

encode() {
    mkdir -p "${final_dir}"
    title=${file%.*}
    echo -e "${c[32]}Processing ${title}...${c[0]}"
    if [ -f "${title}.webp" ]; then
        if [ "$type" = music ] || [ "$type" = album ]; then
            ffmpeg -y -i "${title}.webp" \
                -map_metadata -1 -map_metadata:s -1 -map_metadata:g -1 -map_chapters -1 -map_chapters:s -1 -map_chapters:g -1 \
                -vf "crop=720:720" \
                "${title}.jpg" >/dev/null 2>&1 ||
                failed Conversion
        else
            ffmpeg -y -i "${title}.webp" \
                -map_metadata -1 -map_metadata:s -1 -map_metadata:g -1 -map_chapters -1 -map_chapters:s -1 -map_chapters:g -1 \
                "${title}.jpg" >/dev/null 2>&1 ||
                failed Conversion
        fi
    fi
    if [ -f "${title}.mp4" ]; then
        language=$(ls "${title}"*".vtt" 2>/dev/null)
        if [ -n "$language" ]; then
            language=${language%.*}
            language=${language##*.}
            ffmpeg -y -i "${title}"*.vtt \
                -map_metadata -1 -map_metadata:s -1 -map_metadata:g -1 -map_chapters -1 -map_chapters:s -1 -map_chapters:g -1 \
                "${title}.srt" >/dev/null 2>&1 ||
                failed Conversion
            ffmpeg -y -i "${title}.mp4" -i "${title}.m4a" -i "${title}.srt" \
                -map 0:v -map 1:a -map 2:s \
                -map_metadata -1 -map_metadata:s -1 -map_metadata:g -1 -map_chapters -1 -map_chapters:s -1 -map_chapters:g -1 \
                -metadata title="${title}" -metadata:s:s:0 language="${language}" \
                -c copy \
                -attach "${title}.jpg" -metadata:s:t filename="$title" -metadata:s:t mimetype=image/jpeg \
                "${final_dir}/${title}.mkv" >/dev/null 2>&1 ||
                failed Conversion
        else
            ffmpeg -y -i "${title}.mp4" -i "${title}.m4a" \
                -map 0:v -map 1:a \
                -map_metadata -1 -map_metadata:s -1 -map_metadata:g -1 -map_chapters -1 -map_chapters:s -1 -map_chapters:g -1 \
                -metadata title="${title}" \
                -c copy \
                -attach "${title}.jpg" -metadata:s:t filename="$title" -metadata:s:t mimetype=image/jpeg \
                "${final_dir}/${title}.mkv" >/dev/null 2>&1 ||
                failed Conversion
        fi
    elif [ "$type" = "album" ] && [ "$is_playlist" = 0 ]; then
        ffmpeg -y -i "${title}.m4a" -i "${title}.jpg" \
            -map 0:a -map 1 \
            -map_metadata -1 -map_metadata:s -1 -map_metadata:g -1 -map_chapters -1 -map_chapters:s -1 -map_chapters:g -1 \
            -metadata title="${track}" -metadata album_artist="${artist}" -metadata artist="${artist}" -metadata album="${album}" -metadata album="${album}" -metadata date="${release_year}" -metadata track="${track_number}" \
            "${final_dir}/${title}.mp3" >/dev/null 2>&1 ||
            failed Conversion
    else
        ffmpeg -y -i "${title}.m4a" -i "${title}.jpg" \
            -map 0:a -map 1 \
            -map_metadata -1 -map_metadata:s -1 -map_metadata:g -1 -map_chapters -1 -map_chapters:s -1 -map_chapters:g -1 \
            -metadata title="${track}" -metadata album_artist="${artist}" -metadata artist="${artist}" -metadata album="${album}" -metadata album="${album}" -metadata date="${release_year}" \
            "${final_dir}/${title}.mp3" >/dev/null 2>&1 ||
            failed Conversion
    fi
    rm -rf ./*
}

if [ $single = 1 ]; then
    heading "YouTube" "Downloader"
    echo -e "${c[32]}Downloading ${file%.*}...${c[0]}"
    if [ "$type" = "video" ]; then
        yt-dlp -f "$video_format","$audio_format" --write-thumbnail --write-subs -o "%(title)s.%(ext)s" "$url" ||
            failed Download
    elif [ "$type" = "music" ]; then
        yt-dlp -f "$audio_format" --write-thumbnail -o "${artist} - ${track}.%(ext)s" "$url" ||
            failed Download
    fi
    encode
elif [ $single = 0 ]; then
    from=1
    to=$playlist_count
    if [ "$type" = "channel" ] || [ "$type" = "playlist" ]; then
        if [ $# -eq 0 ]; then
            echo "It's a ${type} link..."
            echo -e "${c[32]}1.${c[0]} Download all videos"
            echo -e "${c[32]}2.${c[0]} Download specific videos or a range"
            echo -ne "${c[33]}Choose one option: ${c[0]}" && read -r choice
        fi
        [ -z "$choice" ] && choice=1
        if [ "$choice" = 2 ]; then
            echo -ne "${c[33]}Enter the indices or the range: ${c[0]}" && read -r indices
            [[ $indices == *-* ]] && from=${indices%-*} && to=${indices#*-}
            [[ $indices == *,* ]] && indices=${indices//,/|} && indices="|$indices|" && single=3
        fi
    fi
    count=1
    if [ "$single" = 3 ]; then
        count_end="${indices//[0-9]/}"
        count_end="${#count_end}"
        ((count_end--))
    else
        count_end=$playlist_count
    fi
    for ((index = from; index <= to; index++)); do
        if [ $single = 3 ]; then
            test="|$index|"
            [[ $indices == *$test* ]] || continue
        fi
        skip=0
        heading "YouTube" "Downloader"
        echo -e "${c[30]}${c[42]}Progress: (${count}/${count_end})${c[0]}"
        ((count++))
        if [ "$type" = "channel" ] || [ "$type" = "playlist" ]; then
            file=$(yt-dlp --no-warnings --print filename --playlist-items "$index" -o "%(playlist_index)s - %(title)s.mkv" "$url")
            echo -e "${c[32]}Downloading ${file%.*}...${c[0]}"
            check
            [ $skip = 1 ] && continue
            yt-dlp -f "$video_format","$audio_format" --playlist-items "$index" --write-thumbnail --write-subs -o "%(playlist_index)s - %(title)s.%(ext)s" "$url" ||
                failed Download
        elif [ "$type" = "album" ]; then
            loading "Extracting tags..." &
            extract_info
            end_loading "Extracting tags..."
            file="${artist} - ${track}.mp3"
            echo -e "${c[32]}Downloading ${file%.*}...${c[0]}"
            check
            [ $skip = 1 ] && continue
            yt-dlp -f "$audio_format" --playlist-items "$index" --write-thumbnail -o "${artist} - ${track}.%(ext)s" "$url" ||
                failed Download
        fi
        encode
    done
fi

rm -rf "${temp_dir}"
rmdir --ignore-fail-on-non-empty "/sdcard/YouTube Videos/.cache"
cd ~ || exit

heading "YouTube" "Downloader"
echo -e "${c[32]}Your ${type} was succesfully downloaded!${c[0]}"
echo -e "${c[32]}You will find your ${type} in ${c[33]}\"${final_dir}\".${c[0]}"
sleep 1
exit 0
