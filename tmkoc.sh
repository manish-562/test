#!/bin/bash

source requirements.sh
color
install "Python" "FFmpeg" "yt-dlp" "python3" "ffmpeg" "yt-dlp"

echo -ne "${c[33]}Enter Episode no: ${c[0]}" && read -r ep

dir="/sdcard/Tmkoc"
url="https://www.sonyliv.com/shows/taarak-mehta-ka-ooltah-chashmah-1700000084"
mkdir -p "$dir"

yt-dlp -f dash-5+bestaudio/dash-6+bestaudio --playlist-items "$ep" -o "${dir}/%(playlist_index)s - %(title)s.%(ext)s" "$url"
