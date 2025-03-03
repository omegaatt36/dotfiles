#!/usr/bin/env bash

set -euo pipefail

# Determine OS
osname=$(uname -s | tr '[:upper:]' '[:lower:]')
if [[ "$osname" == "darwin" ]]; then
    osname="darwin"
elif [[ "$osname" == "linux" ]]; then
    osname="linux"
else
    echo "Unsupported OS: $osname"
    exit 1
fi

# Determine architecture
arch=$(uname -m)
case "$arch" in
    x86_64|amd64)
        arch="amd64"
        ;;
    arm64|aarch64)
        arch="arm64"
        ;;
    *)
        echo "Unsupported architecture: $arch"
        exit 1
        ;;
esac

# Construct the download URL
url="https://github.com/wakatime/wakatime-cli/releases/latest/download/wakatime-cli-${osname}-${arch}.zip"

# Determine the installation directory
install_dir="/usr/local/bin"

# Download the wakatime-cli zip file
echo "Downloading wakatime-cli from $url"
curl -sSL "$url" -o /tmp/wakatime-cli.zip

# Unzip the downloaded file
echo "Unzipping wakatime-cli"
unzip -o /tmp/wakatime-cli.zip -d /tmp/wakatime-cli

# Move the executable to the installation directory
echo "Installing wakatime-cli to $install_dir"
mv /tmp/wakatime-cli/wakatime-cli-${osname}-${arch} "${install_dir}/wakatime-cli"

# Make the executable runnable
chmod +x "${install_dir}/wakatime-cli"

# Clean up temporary files
rm -rf /tmp/wakatime-cli.zip /tmp/wakatime-cli

echo "wakatime-cli installed successfully!"
