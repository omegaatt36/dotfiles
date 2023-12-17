#!/bin/bash

SRC=${PWD}

function install_rust() {
  cd "${HOME}" || exit 1
  sudo apt install build-essential -y
  curl --proto '=https' --tlsv1.3 https://sh.rustup.rs -sSf | sh
  source "${HOME}"/.cargo/env
  cargo install eza
  cargo install topgrade
  cargo install bottom
  cargo install bat

  mkdir -p .config/bottom
  cp "${SRC}"/.config/bottom/bottom.toml .config/bottom
  cp "${SRC}"/.config/topgrade.toml .config/
  cd - || exit 1
}

function install_vscode() {
  curl 'https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64' -o "${HOME}/vscode.deb"
  sudo apt install "${HOME}/vscode.deb" -y
}

function install_go() {
  cd "${HOME}" || exit 1
  local go_version="1.20"

  wget "https://go.dev/dl/go${go_version}.linux-amd64.tar.gz"
  rm -rf "${HOME}/go" && tar -xzf go${go_version}.linux-amd64.tar.gz
  cd - || exit 1
}

function install_tmux() {
  sudo apt install tmux -y
  git clone https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
  curl https://raw.githubusercontent.com/omegaatt36/lab/main/rc/.tmux.conf -o "${HOME}/.tmux.conf"
}

function install_zsh() {
  sudo apt install git curl zsh -y
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" -y

  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"/plugins/zsh-syntax-highlighting
  git clone https://github.com/sobolevn/wakatime-zsh-plugin.git "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}"/plugins/wakatime

  source "${HOME}/.zshrc"
}

function install_fzf() {
  git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}"/.fzf
  "${HOME}"/.fzf/install
}
