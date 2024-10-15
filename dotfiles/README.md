# Dotfiles and Scripts

This repository contains various configuration files (dotfiles) and utility scripts for setting up and customizing a development environment.

## Contents

- `.script/`: Directory containing utility scripts and configuration files
  - `.config/`: Configuration files for various tools
    - `bottom/`: Configuration for the bottom system monitor
    - `topgrade.toml`: Configuration for the topgrade update tool
  - `environment`: Environment variables setup
  - `goinstall.sh`: Script for installing Go packages using Docker
  - `install.sh`: Main installation script for setting up the environment
  - `install_fonts.sh`: Script for installing Nerd Fonts

## Key Features

- Automated installation of common development tools and utilities
- Configuration for zsh, tmux, vim, and other command-line tools
- Custom Go package installation using Docker
- Font installation for both Linux and Windows (WSL) environments

## Usage

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/dotfiles.git
   ```

2. Run the main installation script:
   ```
   ./dotfiles/.script/install.sh
   ```

3. For font installation:
   ```
   ./dotfiles/.script/install_fonts.sh
   ```
   Use the `--windows` flag for Windows/WSL environments.

## Customization

Feel free to modify the configuration files and scripts to suit your needs. The main areas for customization are:

- `.config/`: Tool-specific configurations
- `install.sh`: Add or remove packages and tools to be installed
- `goinstall.sh`: Adjust Docker settings for Go package installation
