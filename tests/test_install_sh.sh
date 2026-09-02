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
printf 'install.sh behavioral checks: passed\n'
