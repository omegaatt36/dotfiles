#!/bin/bash

_SCRIPTDIR="${HOME}/dotfiles/.script"

check_sudo() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "sudo"
    fi
}

install_packages() {
    if [ -z "$*" ]; then
        echo "No packages specified."
        exit 1
    fi

    local DISTRO_INSTALL
    if [ "$(uname -s)" == "Darwin" ]; then
        DISTRO_INSTALL="brew install $*"
    elif [ -f /etc/os-release ]; then
        source /etc/os-release
        if [[ "$ID" == "debian" || "$ID" == "ubuntu" ]]; then
            DISTRO_INSTALL="$(check_sudo) apt install -y $*"
        elif [[ "$ID" == "opensuse" || "$ID" == "opensuse-tumbleweed" ]]; then
            DISTRO_INSTALL="$(check_sudo) zypper in -y $*"
        else
            echo "Unknown distribution. Cannot install packages."
            exit 1
        fi
    else
        echo "This system does not have /etc/os-release."
        exit 1
    fi

    if [ -z "$DISTRO_INSTALL" ]; then
        echo "No installation command found for this distribution."
        exit 1
    fi

    eval "$DISTRO_INSTALL"
}

function install_homebrew() {
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

function install_rust() {
    cd "${HOME}" || exit 1
    curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh
    source "${HOME}/.cargo/env"
    install_packages eza eza-zsh-completion \
    zoxide \
    topgrade \
    bottom \
    bat bat-zsh-completion \
    git-delta \
    fd fd-zsh-completio
    mkdir -p .config/bottom
    mkdir -p .config/zellij
    cp "${_SCRIPTDIR}"/.config/bottom/bottom.toml .config/bottom
    cp "${_SCRIPTDIR}"/.config/topgrade.toml .config/
    cd - || exit 1
}

function install_go() {
    cd "${HOME}" || exit 1
    local go_version="1.23.6"
    local os_type=$(uname -s)
    local arch_type=$(uname -m)
    local go_os_arch
    local download_url

    case "${os_type}-${arch_type}" in
        Darwin-arm64)
            go_os_arch="darwin-arm64"
            ;;
        Linux-x86_64)
            go_os_arch="linux-amd64"
            ;;
        Darwin-x86_64)
            go_os_arch="darwin-amd64"
            ;;
        *)
            echo "Unsupported OS/architecture: ${os_type}-${arch_type}"
            exit 1
            ;;
    esac

    download_url="https://go.dev/dl/go${go_version}.${go_os_arch}.tar.gz"

    # fetch
    wget "${download_url}"

    # remove old version
    $(check_sudo) rm -rf "${HOME}/go"
    $(check_sudo) rm -rf /usr/local/go

    # installk new version
    tar -xzf "go${go_version}.${go_os_arch}.tar.gz"
    $(check_sudo) cp -r go /usr/local/

    # clearup and exit
    rm "go${go_version}.${go_os_arch}.tar.gz"
    cd - || exit 1
}

function install_tmux() {
    install_packages tmux
    git clone https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
    curl https://raw.githubusercontent.com/omegaatt36/lab/main/rc/.tmux.conf -o "${HOME}/.tmux.conf"
}

function install_zellij() {
    install_packages zellij
    cp "${_SCRIPTDIR}"/.config/zellij/config.kdl ${HOME}/.config/zellij/
}

function install_zsh() {
    local os_type=$(uname -s)
    if [ "${os_type}" != "Darwin" ]; then
        install_packages zsh
    fi

    install_packages git curl
    RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" -y

    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/zsh-syntax-highlighting
    git clone https://github.com/sobolevn/wakatime-zsh-plugin.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"/plugins/wakatime
    git clone --depth 1 https://github.com/unixorn/fzf-zsh-plugin.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-zsh-plugin
    git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}/plugins/fzf-tab
    ./bin/chezmoi update --force
    zsh -c 'source "${HOME}/.zshrc"; exec zsh'
}

function install_vimplugin() {
  curl -fLo "${HOME}"/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

  vim +'PlugInstall --sync' +qa
}

function install_fzf() {
  git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}"/.fzf
  curl https://raw.githubusercontent.com/junegunn/fzf-git.sh/main/fzf-git.sh -o ${HOME}/.fzf/fzf-git.sh
  https://raw.githubusercontent.com/junegunn/fzf-git.sh/main/fzf-git.sh
  "${HOME}"/.fzf/install
}
