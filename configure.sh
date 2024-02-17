#!/bin/bash

source requirements.sh

color
heading "Environment" "Configuration"

if [ $# -eq 0 ]; then
    echo -e "${c[33]}Select enviornments for configuration...${c[0]}"
    env_display=("Visual Studio Code" "Code Server" "ZSH" "Python" "Shell Scripting" "C/C++" "R Programming")
    env_init=("dl_code" "dl_code_server" "dl_zsh" "dl_python" "dl_bash" "dl_cpp" "dl_r")
    for ((index = 0; index < ${#env_display[@]}; index++)); do
        echo -e "${c[34]}$((index + 1)): ${env_display[index]}${c[0]}"
    done
    echo -ne "${c[33]}Enter Indices: ${c[0]}" && read -r indices
    if [ -z "$indices" ]; then
        env=("dl_zsh")
    elif [[ $indices == *-* ]]; then
        env=("${env_init[@]:((${indices%-*} - 1)):((${indices#*-} - ${indices%-*} + 1))}")
    else
        if [[ $indices == *,* ]]; then
            env=()
            indices=${indices//,/' '}
        fi
        for index in $indices; do
            env+=("${env_init[index - 1]}")
        done
    fi
elif [ $# -ge 1 ]; then
    env_init=("$@")
    env=()
    for dl_pkg in "${env_init[@]}"; do
        env+=("dl_$dl_pkg")
    done
else
    echo -e "${c[31]}Too any arguements provided...${c[0]}"
    exit 1
fi

install_ext() {
    install "Wget" "gunzip" "wget" "gunzip"
    extentions=("$@")
    for editor in code code-server; do
        for extension in "${extentions[@]}"; do
            if command -v "$editor" >/dev/null && ! "$editor" --list-extensions | grep -q "$extension"; then
                pub=${extension%.*}
                ext=${extension#*.}
                loading "Installing ${c[33]}${ext}${c[32]} by ${c[34]}${pub}${c[32]}..." &
                "$editor" --install-extension "${extension}" >/dev/null 2>&1
                if ! "$editor" --list-extensions | grep -q "$extension"; then
                    end_loading "Installing ${c[33]}${ext}${c[32]} by ${c[34]}${pub}${c[32]}..." "failed"
                    loading "Trying to install ${c[33]}${extension}${c[32]} from marketplace..." &
                    url="https://marketplace.visualstudio.com/items?itemName=${extension}"
                    ext_info=$(curl -s "$url" | grep \"Version\")
                    ext_info=${ext_info#*'>'}
                    ext_info=${ext_info%'<'*}
                    version=$(echo "$ext_info" | jq -r .Resources.Version)
                    works_with=$(echo "$ext_info" | jq -r .WorksWith)
                    if [[ $works_with == *'Universal'* ]]; then
                        url="https://marketplace.visualstudio.com/_apis/public/gallery/publishers/${pub}/vsextensions/${ext}/${version}/vspackage"
                    else
                        url="https://marketplace.visualstudio.com/_apis/public/gallery/publishers/${pub}/vsextensions/${ext}/${version}/vspackage?targetPlatform=linux-arm64"
                    fi
                    SECONDS=0
                    successful=false
                    while [ $SECONDS -lt 30 ]; do
                        if wget -O "${HOME}/.cache/${extension}.gz" "$url" >/dev/null 2>&1; then
                            successful=true
                            break
                        fi
                    done
                    if $successful; then
                        gunzip "${HOME}/.cache/${extension}.gz"
                        mv "${HOME}/.cache/${extension}" "${HOME}/.cache/${extension}.vsix"
                        "$editor" --install-extension "${HOME}/.cache/${extension}.vsix" >/dev/null 2>&1
                        end_loading "Trying to install ${c[33]}${extension}${c[32]} from marketplace..."
                    else
                        end_loading "Trying to install ${c[33]}${extension}${c[32]} from marketplace..." "failed"
                    fi
                fi
                end_loading "Installing ${c[33]}${ext}${c[32]} by ${c[34]}${pub}${c[32]}..."
            fi
        done
    done
}

dl_code() {
    heading "Code" "Installer"

    install "Wget" "GPG" "wget" "gpg"

    heading "Code" "Installer"
    if ! command -v code >/dev/null; then
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >packages.microsoft.gpg
        sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
        sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
        rm -f packages.microsoft.gpg
        install "apt-transport-https" "apt-transport-https"
        heading "Code" "Installer"
        install "Visual Studio Code" "code"
    fi

    cp "./Files/code.desktop" "/usr/share/applications/code.desktop"
    mkdir -p "$HOME/.config/Code/User"
    cp "./Files/code" "/usr/local/bin/code"
    chmod +x "/usr/local/bin/code"
    cp "./Files/settings.json" "$HOME/.config/Code/User/settings.json"
    heading "Code" "Installer"
    install_ext "dracula-theme.theme-dracula" "PKief.material-icon-theme" "GitHub.github-vscode-theme" "esbenp.prettier-vscode"

    heading "Code" "Installer"
    echo -e "${c[33]}Visual Studio Code is successfully installed.${c[0]}"
}

dl_code_server() {
    heading "Code-Server" "Installer"
    install "Curl" "curl"

    heading "Code-Server" "Installer"
    if [ "$HOME" = "/data/data/com.termux/files/home" ]; then
        install "Termux-User-Repository" "code-server" "tur-repo" "code-server"
        heading "Code-Server" "Installer"
    elif ! command -v code-server >/dev/null; then
        curl -fsSL https://code-server.dev/install.sh | sh
    fi

    heading "Code-Server" "Installer"
    mkdir -p "$HOME/.config/code-server/" "$HOME/.local/share/code-server/User/"
    cp "./Files/config.yaml" "$HOME/.config/code-server/config.yaml"
    cp "./Files/settings.json" "$HOME/.local/share/code-server/User/settings.json"
    cp "./Files/keybindings.json" "$HOME/.local/share/code-server/User/keybindings.json"
    install_ext "EditorConfig.EditorConfig" "dracula-theme.theme-dracula" "PKief.material-icon-theme" "GitHub.github-vscode-theme" "esbenp.prettier-vscode"

    heading "Code-Server" "Installer"
    echo -e "${c[33]}Code-server is successfully installed.${c[0]}"
}

dl_zsh() {
    heading "ZSH" "Configuration"
    install "Git" "ZSH" "Curl" "Wget" "git" "zsh" "curl" "wget"
    [ -z "$pass" ] && echo -ne "${c[33]}Enter your password: ${c[0]}" && read -ers pass

    if [ ! -d "$HOME/.oh-my-zsh/" ]; then
        heading "ZSH" "Configuration"
        yes n | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    fi

    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
        heading "ZSH" "Configuration"
        git clone --depth=1 "https://github.com/romkatv/powerlevel10k.git" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
        cp "./Files/.zshrc" "$HOME/"
        cp "./Files/.p10k.zsh" "$HOME/"
    fi

    heading "ZSH" "Configuration"
    theme="\"powerlevel10k/powerlevel10k\""
    old_theme="\"robbyrussell\""
    ! grep -q "ZSH_THEME=${theme}" "$HOME/.zshrc" &&
        sed -i "s/ZSH_THEME=${old_theme}/ZSH_THEME=${theme}/" "$HOME/.zshrc"

    ! test -d "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions" &&
        git clone "https://github.com/zsh-users/zsh-autosuggestions" "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
    ! grep -q "plugins=(.*zsh-autosuggestions.*)" "$HOME/.zshrc" &&
        sed -i "/^plugins=/ s/)/ zsh-autosuggestions)/" "$HOME/.zshrc"

    ! test -d "${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" &&
        git clone "https://github.com/zsh-users/zsh-syntax-highlighting" "${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
    ! grep -q "plugins=(.*zsh-syntax-highlighting.*)" "$HOME/.zshrc" &&
        sed -i "/^plugins=/ s/)/ zsh-syntax-highlighting)/" "$HOME/.zshrc"

    echo "$pass" | chsh -s "$(command -v zsh)"

    git config --global user.name "Dhanush Shetty"
    git config --global user.email dhanushshetty2412@gmail.com
    git config --global core.editor "code --wait"
    git config --global core.autocrlf input
    git config --global init.defaultBranch main
    git config --global credential.helper store
    git config --global diff.tool vscode
    git config --global difftool.vscode.cmd "code --wait --diff \$LOCAL \$REMOTE"
    git config --global difftool.prompt false

    termux_dir="/data/data/com.termux/files/home/.termux"
    font_url="https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/patched-fonts/UbuntuMono/Regular/UbuntuMonoNerdFontMono-Regular.ttf"
    mkdir -p "$termux_dir"
    test -f "${termux_dir}/font.ttf" || wget -O "${termux_dir}/font.ttf" "$font_url"
    test -f "${termux_dir}/colors.properties" || cp ./Files/colors.properties "${termux_dir}/colors.properties"

    heading "ZSH" "Configuration"
    install_ext "eamodio.gitlens" "mhutchie.git-graph"

    heading "ZSH" "Configuration"
    echo -e "${c[33]}Z-shell successfully installed with git plugin...${c[0]}"
}

dl_python() {
    heading "Python" "Configuration"
    install "Python" "autopep8" "python3" "autopep8"
    loading "Installing Pylint..." &
    pip3 install pylint >/dev/null 2>&1
    end_loading "Installing Pylint..."
    heading "Python" "Configuration"
    install_ext "ms-python.python" "ms-python.pylint" "ms-python.autopep8" "formulahendry.code-runner"
}

dl_bash() {
    heading "Shell Scripting" "Configuration"
    install "shfmt" "ShellCheck" "shfmt" "shellcheck"
    cp "./Files/.shellcheckrc" "$HOME/.shellcheckrc"
    heading "Shell Scripting" "Configuration"
    install_ext "mkhl.shfmt" "timonwong.shellcheck" "foxundermoon.shell-format"
}

dl_cpp() {
    heading "C/C++" "Configuration"
    install "GCC" "G++" "gcc" "g++"
    heading "C/C++" "Configuration"
    install_ext "ms-vscode.cpptools" "formulahendry.code-runner"
}

dl_r() {
    heading "R Programming" "Configuration"
    if [ "$HOME" = "/data/data/com.termux/files/home" ]; then
        echo -e "${c[31]}Sorry R cannot be installed on your machine!${c[0]}"
        echo -e "${c[33]}Switch to root and try again.${c[0]}"
    else
        apt install -y r-cran-tidyverse
        heading "R Programming" "Configuration"
        Rscript -e 'install.packages("languageserver")'
    fi
    install_ext "REditorSupport.r" "formulahendry.code-runner"
}

for env_func in "${env[@]}"; do
    $env_func
done
