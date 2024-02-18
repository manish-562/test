#!/bin/bash

source requirements.sh

color
heading "F-droid" "Updater"
install "Curl" "Wget" "AAPT" "curl" "wget" "aapt"

check() {
    pkg_info=$(aapt dump badging "$apk" | grep package:)
    pkg_name=${pkg_info#*"name='"}
    pkg_name=${pkg_name%%"'"*}
    current_version=${pkg_info#*"versionCode='"}
    current_version=${current_version%%"'"*}
    latest_version=$(curl -s "https://f-droid.org/en/packages/${pkg_name}/" | grep -m 1 "<b>Version")
    latest_version=${latest_version##*"("}
    latest_version=${latest_version%")"*}
    if [ "$current_version" = "$latest_version" ] || [ -z "$latest_version" ]; then
        return 0
    else
        return 1
    fi
}

download() {
    for apk in *.apk; do
        if check "$apk"; then
            echo -e "${c[34]}${apk%'_v'*} is up to date${c[0]}"
            up_to_date="${up_to_date}${apk%'_v'*}\n"
            continue
        else
            loading "Updating ${apk%'_v'*}..." &
            if wget -O temp.apk "https://f-droid.org/repo/${pkg_name}_${latest_version}.apk" >/dev/null 2>&1; then
                updated="${updated}${apk%'_v'*}\n"
                rm "$apk"
                app_name=$(aapt dump badging "temp.apk" | grep application-label:)
                app_name=${app_name#*"application-label:'"}
                app_name=${app_name%%"'"*}
                apk_version=$(aapt dump badging "temp.apk" | grep package:)
                apk_version=${apk_version#*"versionName='"}
                apk_version=${apk_version%%"'"*}
                mv "temp.apk" "${app_name//':'/'_'}_v${apk_version}.apk"
            else
                failed="${failed}${apk%'_v'*}\n"
            fi
            end_loading "Updating ${apk%'_v'*}..."
        fi
    done
}

result() {
    echo -e "\n"
    [ -n "$up_to_date" ] &&
        {
            echo -e "${c[34]}The following packages were up to date${c[0]}"
            echo -e "${c[33]}$up_to_date${c[0]}"
        }
    [ -n "$updated" ] &&
        {
            echo -e "${c[32]}The following packages were updated${c[0]}"
            echo -e "${c[33]}$updated${c[0]}"
        }
    [ -n "$failed" ] &&
        {
            echo -e "${c[31]}The following package update failed${c[0]}"
            echo -e "${c[33]}$failed${c[0]}"
        }
}

heading "F-droid" "Updater"
cd "/sdcard/Apps/F-droid" || exit
download

cd "/sdcard/Apps/Termux" || exit
download
heading "F-droid" "Updater"
result
exit 0
