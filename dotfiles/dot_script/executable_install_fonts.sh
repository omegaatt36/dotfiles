#!/bin/bash

declare target="linux"
declare repo="ryanoasis/nerd-fonts"
declare -a fonts=(
  FiraCode
  Meslo
)

if ! ARGS=$(getopt -o p --long windows -- "$@"); then
  echo "getopt failed: " $ARGS
  exit 1
fi

eval set -- "${ARGS}"

while true
do
case "$1" in
  -p|--windows)
    target=windows
    shift
    ;;
  --)
    shift
    break
    ;;
esac
done

get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
    grep '"tag_name":' |
    sed -E 's/.*"([^"]+)".*/\1/'
}

function install_linux_fonts() {
  local fonts_dir
  fonts_dir="${HOME}/.local/share/fonts"
  if [[ ! -d "$fonts_dir" ]]; then
    mkdir -p "$fonts_dir"
  fi

  find "$@" -name "*.ttf" -exec mv {} "$fonts_dir" \;

  # fc-cache -fv
}

# Install font for the current user. It'll appear in "Font settings".
function install_windows_fonts() {
  local dst_dir
  dst_dir=$(wslpath "$(cmd.exe /c "echo %LOCALAPPDATA%\Microsoft\\Windows\\Fonts" 2>/dev/null | sed 's/\r$//')")
  mkdir -p "$dst_dir"
  local src
  for src in "$@"; do
    local file
    file=$(basename "$src")

    test -f "$dst_dir/$file" || cp -f "$src" "$dst_dir/"
    local win_path
    win_path=$(wslpath -w "$dst_dir/$file")
    echo "$win_path"
    reg.exe add                                                      \
      "HKCU\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts" \
      /v "${file%.*} (TrueType)"  /t REG_SZ /d "$win_path" /f 2>/dev/null
  done
}


function main() {
  local version
  version=$( get_latest_release $repo )
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  trap 'rm -rf ${tmp_dir@Q}' INT TERM EXIT

  for font in "${fonts[@]}"; do
    zip_file="${font}.zip"
    download_url="https://github.com/$repo/releases/download/${version}/${zip_file}"
    echo "Downloading $download_url"
    wget -q --show-progress -P "$tmp_dir" "$download_url"
    # unzip -o means replace file without asking.
    unzip -o "$tmp_dir/$zip_file" -d "$tmp_dir"
    rm "$tmp_dir/$zip_file"
  done
  find "$tmp_dir" -name '*Windows Compatible*' -delete

  if [ "$target" = "linux" ]
  then
    install_linux_fonts "$tmp_dir"
  elif [ "$target" = "windows" ]
  then
    install_windows_fonts "$tmp_dir/*.ttf"
  fi
}

set -xe

main

echo -e '\033[0;32m'
echo 'Fonts successfully installed.'
echo -e '\033[0m'