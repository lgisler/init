#! /usr/bin/env bash

set -euxo pipefail

ZSH_PATH="$HOME/.zshrc"

echo "alias cdl='cd \${HOME}/dev/LumPDK/'" >> $ZSH_PATH
echo "alias dev='docker compose -f "\${HOME}/dev/LumPDK/.devcontainer/compose.yaml" run --rm focal zsh'" >> $ZSH_PATH
echo "alias dev-bash='docker compose -f "\${HOME}/dev/LumPDK/.devcontainer/compose.yaml" run --rm focal bash'" >> $ZSH_PATH
echo "alias devbuild='docker compose -f "\${HOME}/dev/LumPDK/.devcontainer/compose.yaml" build --build-arg user_id=\$(id -u) --build-arg group_id=\$(id -g) focal'" >> $ZSH_PATH
echo "alias nix='source \${HOME}/.nix-profile/etc/profile.d/nix.sh'" >> $ZSH_PATH
