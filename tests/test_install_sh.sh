#!/usr/bin/env bash
set -euo pipefail

script="${1:-install.sh}"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
contains() { grep -Fq -- "$1" "$script" || fail "missing: $1"; }

bash -n "$script"
contains 'sudo -v'
contains 'sudo chsh -s "$ZSH_PATH" "$USER"'
contains 'command -v docker'
contains '/etc/apt/keyrings/docker.asc'
contains 'https://download.docker.com/linux/ubuntu'
contains 'vim ca-certificates gnupg'
contains 'GIT_TERMINAL_PROMPT=0'
contains 'Дополнительные компоненты'
contains 'Docker Engine + Compose'
contains 'Инструменты сервера (htop, tmux, unzip, ncdu)'
contains 'read -r selected </dev/tty'
contains 'INSTALL_DOCKER=1'
contains 'INSTALL_TOOLS=1'
contains 'INSTALL_DOCKER=${INSTALL_DOCKER:-0}'
if grep -Fq 'git -C "$PLUGIN_DIR" pull' "$script"; then
  fail 'existing plugins must be skipped rather than updated'
fi
printf 'install.sh behavioral checks: passed\n'
