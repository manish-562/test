#!/bin/bash

color() {
    bg_color=-1
    if [ $# -eq 0 ]; then
        for i in {0..120}; do
            c[i]="\x1b[${i}m"
        done
    elif [ $# -eq 1 ] || [ $# -eq 2 ]; then
        R=$(printf "%d" 0x"${1:0:2}")
        G=$(printf "%d" 0x"${1:2:2}")
        B=$(printf "%d" 0x"${1:4:2}")
        bg_color=0
        if [ $# -eq 2 ]; then
            r=$(printf "%d" 0x"${2:0:2}")
            g=$(printf "%d" 0x"${2:2:2}")
            b=$(printf "%d" 0x"${2:4:2}")
            bg_color=1
        fi
    elif [ $# -eq 3 ] || [ $# -eq 6 ]; then
        R=$1
        G=$2
        B=$3
        bg_color=0
        if [ $# -eq 6 ]; then
            r=$4
            g=$5
            b=$6
            bg_color=1
        fi
    fi
    if [ "$bg_color" -eq 0 ]; then
        color="\x1b[38;2;${R};${G};${B}m"
    elif [ "$bg_color" -eq 1 ]; then
        color="\x1b[38;2;${R};${G};${B}m\x1b[48;2;${r};${g};${b}m\x1b[1m"
    fi
}

heading() {
    install "Figlet" "figlet"
    clear
    color "ffff00"
    figlet "$1" | sed "s/^/${color}${c[1]}/; s/$/${c[0]}/"
    figlet "$2" | sed "s/^/${c[34]}${c[1]}/; s/$/${c[0]}/"
}

loading() {
    chars=("/" "-" "\\" "|")
    while true; do
        message="$1"
        for char in "${chars[@]}"; do
            echo -ne "\r${c[32]}${message}${char} ${c[0]}"
            sleep 0.2
        done
    done
}

end_loading() {
    message="$1"
    status="$2"
    [ -z "$status" ] && status="done"
    if [ "$status" = "done" ]; then
        status="${c[33]}${status}"
    elif [ "$status" = "failed" ]; then
        status="${c[31]}${status}"
    else
        status="${c[34]}${status}"
    fi
    if kill $! >/dev/null 2>&1; then
        echo -e "\r${c[32]}${message}${c[33]}${status}!${c[0]}"
        sleep 1
    fi
}

install() {
    at_home=false
    if [ "$HOME" = "/data/data/com.termux/files/home" ]; then
        source "./Files/termux_adapter.sh"
    elif [ "$HOME" = "/root" ] && ! command -v sudo >/dev/null; then
        apt update -y
        apt install sudo -y
    else
        at_home=true
    fi
    args=("$@")
    length=${#args[@]}
    midpoint=$((length / 2))
    packages=("${args[@]:0:$midpoint}")
    commands=("${args[@]:$midpoint}")
    pkg_installed=1
    for index in "${!commands[@]}"; do
        if command -v "${commands[index]}" >/dev/null || dpkg -l | grep -q "ii  ${commands[index]} " >/dev/null; then
            packages[index]="${c[32]}${packages[index]}${c[0]}"
            unset "commands[index]"
        else
            packages[index]="${c[31]}${packages[index]}${c[0]}"
            pkg_installed=0
        fi
    done
    if [ $pkg_installed -eq 0 ]; then
        echo -e "${c[31]}E:${c[0]} Some packages are not installed"
        echo -e "${packages[@]}"
        echo "What would you like to do???:"
        echo -e "${c[32]}1.${c[34]} Install the packages from the repository${c[0]}"
        echo -e "${c[32]}2.${c[34]} Install the packages from a backup${c[0]}"
        echo -e "${c[32]}3.${c[34]} Terminate the script${c[0]}"
        echo -ne "${c[33]}Choose one option: ${c[0]}" && read -r choice
        case "$choice" in
        1)
            [ -z "$pass" ] && $at_home && echo -ne "${c[33]}Enter your password: ${c[0]}" && read -ers pass
            loading "Updating Packages..." &
            echo "$pass" | sudo -S apt update -y >/dev/null 2>&1
            yes y | sudo apt upgrade -y >/dev/null 2>&1
            end_loading "Updating Packages..."
            for package in "${commands[@]}"; do
                loading "Installing ${package}..." &
                sudo apt install -y "$package" >/dev/null 2>&1 ||
                    {
                        [[ $(curl -s "https://pypi.org/pypi/${package}/json") == *"Not Found"* ]] ||
                            {
                                if ! command -v pip3 >/dev/null; then
                                    sudo apt install -y python3-pip >/dev/null 2>&1 ||
                                        sudo apt install -y python-pip >/dev/null 2>&1
                                fi
                                pip3 install "$package" >/dev/null 2>&1
                            }
                    }
                end_loading "Installing ${package}..."
            done
            ;;
        2)
            echo "Enter the source to the backup file: "
            read -r backup
            tar -zxf "$backup" -C /data/data/com.termux/files --recursive-unlink --preserve-permissions
            ;;
        3)
            echo -e "${c[31]}Terminating the script${c[0]}"
            sleep 1
            exit 0
            ;;
        *)
            echo -e "Invalid choice. ${c[31]}Terminating the script${c[0]}"
            exit 1
            ;;
        esac
        pkg_installed=1
        for index in "${!commands[@]}"; do
            command -v "${commands[index]}" >/dev/null || dpkg -l | grep -q "ii  ${commands[index]} " >/dev/null
            if [ $? -eq 1 ]; then
                pkg_installed=0
            fi
        done
        if [ "$pkg_installed" -eq 0 ]; then
            echo -e "${c[31]}There seems to be a issue. \nTry installing the packages manually${c[0]}"
            exit 1
        elif [ "$pkg_installed" -eq 1 ]; then
            echo -e "${c[32]}All requirements are met, you are good to go${c[0]}"
            sleep 2
        fi
        clear
    fi
}
