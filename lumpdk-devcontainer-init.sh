#/usr/bin/env bash

set -euxo pipefail

sudo chown -R "${USER}":"${USER}" "${HOME}"
sudo chown -R "${USER}":"${USER}" /nix
sudo apt-get update
sudo apt-get install -y firefox zsh vim

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
alias cdl="cd \${HOME}/LumPDK/"
alias bg="bzr gazelle"
alias bbq="bzt --config=quality"
export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/\$(id -u)/bus
EOF
