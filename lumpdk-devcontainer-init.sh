#!/usr/bin/env bash

set -euxo pipefail

sudo chown -R "${USER}":"${USER}" "${HOME}"
sudo chown -R "${USER}":"${USER}" /nix
sudo apt-get update
sudo apt-get install -y firefox zsh vim curl wget gnupg2 software-properties-common

# install cursor-agent cli tool
curl https://cursor.com/install -fsSL | bash
export PATH="$HOME/.cursor/bin:$PATH"

LUM="${HOME}/LumPDK"
"${LUM}/bootstrap.py"
source "${HOME}/.nix-profile/etc/profile.d/nix.sh"
ln -s "${HOME}/.config" "${LUM}/.config"

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

cat <<EOF > "${HOME}/.zshrc"
export ZSH="\${HOME}/.oh-my-zsh"
ZSH_THEME="evan"
HOST="dkr"
plugins=(git bazel)
source "\${ZSH}/oh-my-zsh.sh"

# LumPDK aliases
alias cdl="cd \${HOME}/LumPDK/"
alias bg="bzr gazelle"
alias bbq="bzt --config=quality"

# Environment
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/\$(id -u)/bus
EOF
