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
        elif [[ "$ID" == "rhel" || "$ID" == "centos" || "$ID" == "rocky" || "$ID" == "fedora" || "$ID_LIKE" == *"rhel"* || "$ID_LIKE" == *"fedora"* ]]; then
            if command -v dnf &> /dev/null; then
                DISTRO_INSTALL="$(check_sudo) dnf install -y $*"
            elif command -v yum &> /dev/null; then
                DISTRO_INSTALL="$(check_sudo) yum install -y $*"
            else
                echo "Neither dnf nor yum found on this RHEL-like system."
                exit 1
            fi
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

function install_helm-ls() {
    echo "Installing helm-ls..."
    local os_type=$(uname -s)
    local arch_type=$(uname -m)
    local asset_name
    local download_url

    # Determine asset name based on OS and architecture
    case "${os_type}-${arch_type}" in
        Darwin-arm64)
            asset_name="helm_ls_darwin_arm64"
            ;;
        Linux-x86_64)
            asset_name="helm_ls_linux_amd64"
            ;;
        # Add other architectures supported by helm-ls if needed
        # e.g., Linux-aarch64 might map to helm_ls_linux_arm64 if that exists
        *)
            echo "Unsupported OS/architecture for helm-ls: ${os_type}-${arch_type}"
            return 1 # Use return instead of exit within function
            ;;
    esac

    if command -v jq &> /dev/null; then
        echo "use jq"
    else
        echo "jq not found, attempting fallback URL extraction with grep/awk..."
    fi
    echo "Determined asset name: $asset_name"

    # Fetch latest release information from GitHub API
    local download_url
    # Use -L to follow redirects which GitHub API might use
    download_url=$(curl -sL https://api.github.com/repos/mrjosh/helm-ls/releases/latest | jq -r ".assets[] | select(.name == \"$asset_name\") | .browser_download_url // \"\"")

    if [ -z "$download_url" ]; then
        echo "Could not find download URL for asset: $asset_name"
        echo "Please check available assets at https://github.com/mrjosh/helm-ls/releases/latest"
        # Show partial API response for debugging purposes
        echo "API response snippet: $(echo "$latest_release_info" | head -n 10)"
        return 1
    fi

    echo "Found download URL: $download_url"

    # Create a temporary directory for download
    local tmp_dir
    tmp_dir=$(mktemp -d)
    if [ ! -d "$tmp_dir" ]; then
        echo "Failed to create temporary directory."
        return 1
    fi
    # Ensure cleanup on function exit (success or failure) or interrupt signals
    # Note: Using RETURN trap might interfere if the script has complex trap handling elsewhere.
    # Consider just cleaning up explicitly before successful return and letting errors exit.
    # Simpler approach without trap: Clean up manually before success/failure returns.
    # Let's stick with trap for now as it's concise, but be aware of potential interactions.
    trap 'echo "Cleaning up temporary directory: $tmp_dir"; rm -rf "$tmp_dir"' RETURN INT TERM HUP

    local download_path="${tmp_dir}/helm-ls_download" # Use a distinct name in tmp dir

    echo "Downloading $asset_name to $download_path..."
    # Use curl with -f to fail silently on server errors (like 404), -L to follow redirects, -o to specify output file
    if ! curl -fL -o "$download_path" "$download_url"; then
        echo "Failed to download helm-ls from $download_url."
        # Cleanup will be handled by the trap on RETURN
        return 1
    fi

    echo "Making helm-ls executable..."
    if ! chmod +x "$download_path"; then
        echo "Failed to make helm-ls executable at $download_path."
        return 1
    fi

    # Standard location for user-installed binaries
    local install_dir="/usr/local/bin"
    local install_path="${install_dir}/helm-ls"

    # Ensure the target directory exists (though /usr/local/bin usually does)
    # This command might need sudo if the directory doesn't exist and isn't writable by the user
    $(check_sudo) mkdir -p "$install_dir"

    echo "Attempting to move helm-ls to $install_path (may require sudo)..."
    # Use the check_sudo function from the script to handle potential sudo requirement
    if ! $(check_sudo) mv "$download_path" "$install_path"; then
        echo "Failed to move helm-ls to $install_path. Check permissions or sudo access."
        # If move fails, the downloaded file remains in tmp_dir and will be cleaned by trap
        return 1
    fi

    # Cleanup is handled by trap upon function return

    echo "helm-ls installed successfully to $install_path."
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
    local go_version="1.25.3"
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

function install_golang_tools() {
    go install golang.org/x/tools/gopls@latest
    go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
    go install github.com/daixiang0/gci@latest
    go install golang.org/x/tools/cmd/goimports@latest
    go install github.com/go-delve/delve/cmd/dlv@latest
    go install github.com/mgechev/revive@latest
    go install github.com/itchyny/gojq/cmd/gojq@latest
    go install honnef.co/go/tools/cmd/staticcheck@latest
    go install github.com/client9/misspell/cmd/misspell@latest
    go install go.uber.org/mock/mockgen@latest
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
  "${HOME}"/.fzf/install
}
