#!/bin/bash

source requirements.sh

color
heading "Ubuntu" "Installer"

copy_repo() {
    repo=$(git config --get remote.origin.url)
    dir="${repo##*'/'}"
    dir="${1}/${dir%.git}"
    git clone "$repo" "${dir}"
}

if [ "$HOME" = "/data/data/com.termux/files/home" ]; then
    install "Proot-Distro" "Git" "proot-distro" "git"

    heading "Ubuntu" "Installer"
    proot-distro install ubuntu
    echo "proot-distro login ubuntu" >"${PREFIX}/bin/ubuntu"
    chmod +x "${PREFIX}/bin/ubuntu"

    [ -f "$HOME/.bashrc" ] && ! grep -q "ubuntu" "$HOME/.bashrc" &&
        sed -i "1i\[ \$(ps -e | grep -cwi proot) -le 2 ] && ubuntu" "$HOME/.bashrc"
    [ -f "$HOME/.zshrc" ] && ! grep -q "ubuntu" "$HOME/.zshrc" &&
        sed -i "1i\[ \$(ps -e | grep -cwi proot) -le 2 ] && ubuntu" "$HOME/.zshrc"

    grep -q "/data/data/com.termux/files/usr/bin" "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu/etc/environment" &&
        sed -i "s|:/data/data/com.termux/files/usr/bin:|:|" "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu/etc/environment"

    copy_repo "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu/root"
elif [ "$HOME" = "/root" ]; then
    echo -ne "${c[33]}Enter your username: ${c[0]}" && read -r user
    echo -ne "${c[33]}Enter your password: ${c[0]}" && read -ers pass
    echo -ne "${c[33]}Enter password again: ${c[0]}" && read -ers pass_cnf
    [ "$pass" != "$pass_cnf" ] && echo -ne "${c[31]}Passwords don't match!${c[0]}" && exit 1

    install "Git" "nano" "Curl" "git" "nano" "curl"
    echo -e "5\n44" | apt install tzdata -y
    echo -e "32\n1" | apt install keyboard-configuration -y

    ! grep -q "${user}" "/etc/passwd" &&
        sudo useradd -m -u 2412 -U -s /bin/bash "${user}"
    echo -e "${pass}\n${pass}" | sudo passwd "${user}"

    ! grep -q "${user}" "/etc/sudoers" &&
        sed -i "/root.*ALL=(ALL:ALL) ALL/a ${user} ALL=(ALL:ALL) ALL" "/etc/sudoers" "/etc/sudoers"

    echo "proot-distro login --user ${user} ubuntu" >"/data/data/com.termux/files/usr/bin/ubuntu"

    cp ./Files/pip.conf "/etc/pip.conf"

    copy_repo "/home/${user}"
else
    install "Gnome" "Terminal" "Tweaks" "DBus" "Yaru-gtk" "Yaru-icon" "File-Manager" "Extensions" "Dock" "VNC" "gnome-shell" "gnome-terminal" "gnome-tweaks" "dbus-x11" "yaru-theme-gtk" "yaru-theme-icon" "nautilus" "gnome-shell-extensions" "gnome-shell-extension-ubuntu-dock" "tigervnc-standalone-server"

    heading "Ubuntu" "Installer"
    if apt list firefox 2>/dev/null | grep -q snap; then
        install software-properties-common software-properties-common
        echo -e "\n" | sudo add-apt-repository ppa:mozillateam/ppa
        cp ./Files/mozilla-firefox "/etc/apt/preferences.d/mozilla-firefox"
        sudo apt remove -y firefox
    fi
    install "FireFox" "firefox"

    heading "Ubuntu" "Installer"
    if ! fc-list | grep -q Nerd; then
        install "Wget" "wget"
        font_dir="/usr/share/fonts/"
        font_url="https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/UbuntuMono/Regular/UbuntuMonoNerdFontMono-Regular.ttf"
        mkdir -p "$font_dir"
        sudo wget -O "${font_dir}/font.ttf" "$font_url"
        sudo fc-cache -f
    fi

    heading "Ubuntu" "Installer"
    mkdir -p "${HOME}/.vnc"
    cp ./Files/xstartup "${HOME}/.vnc/"
    chmod +x "${HOME}/.vnc/xstartup"
    find /usr -type f -iname "*login1*" -delete

    export DISPLAY=:1
    grep -q "DISPLAY=:1" /etc/environment ||
        echo "DISPLAY=:1" >>/etc/environment
    echo "vncserver :1 -geometry 2000x1000" >"/usr/local/bin/vncstart"
    echo "vncserver -kill :1" >"/usr/local/bin/vncstop"
    chmod +x "/usr/local/bin/vncstart" "/usr/local/bin/vncstop"

    if vncstart; then
        gsettings set org.gnome.desktop.interface font-name 'UbuntuMono Nerd Font Mono 11'
        gsettings set org.gnome.desktop.interface monospace-font-name 'UbuntuMono Nerd Font Mono 11'
        gsettings set org.gnome.desktop.interface document-font-name 'UbuntuMono Nerd Font Mono 11'
        gsettings set org.gnome.desktop.wm.preferences titlebar-font 'UbuntuMono Nerd Font Mono 11'

        gsettings set org.gnome.desktop.interface gtk-theme 'Yaru'
        gsettings set org.gnome.desktop.interface icon-theme 'Yaru'
        gsettings set org.gnome.desktop.interface cursor-theme 'Yaru'
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        gsettings set org.gnome.desktop.background picture-uri '/usr/share/backgrounds/warty-final-ubuntu.png'
        gsettings set org.gnome.desktop.background picture-uri-dark 'file:///usr/share/backgrounds/warty-final-ubuntu.png'
        gsettings set org.gnome.mutter dynamic-workspaces false
        gsettings set org.gnome.desktop.wm.preferences num-workspaces 1

        gnome-extensions enable ubuntu-dock@ubuntu.com
        gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'LEFT'
        gsettings set org.gnome.shell.extensions.dash-to-dock extend-height true
        gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 80
        gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false
        gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'firefox.desktop', 'org.gnome.Extensions.desktop', 'org.gnome.tweaks.desktop', 'org.gnome.Terminal.desktop', 'code.desktop', 'org.gnome.Settings.desktop']"
        vncstop
    fi
fi
