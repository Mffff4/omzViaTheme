#!/usr/bin/env bash

set -e

OS="$(uname -s)"
case "$OS" in
    Darwin)  SED_EXT="";;
    Linux)   SED_EXT="";;
    *)       err "OS $OS not supported";;
esac

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
info() { echo -e "${CYAN}[→]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

info "Устанавливаем зависимости (zsh, git, curl)..."
if [ "$OS" = "Darwin" ]; then
    if ! command -v brew >/dev/null 2>&1; then
        warn "Homebrew не найден, устанавливаем..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install zsh git curl
elif [ "$OS" = "Linux" ]; then
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -q
        sudo apt-get install -y zsh git curl
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y zsh git curl
    else
        err "Менеджер пакетов не поддерживается. Установите zsh, git, curl вручную."
    fi
fi
log "Зависимости установлены"

if [ -d "$HOME/.oh-my-zsh" ]; then
    warn "Oh My Zsh уже установлен, пропускаем..."
else
    info "Устанавливаем Oh My Zsh (unattended)..."
    RUNZSH=no CHSH=no \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        "" --unattended
    log "Oh My Zsh установлен"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

info "Устанавливаем тему passion..."
PASSION_REPO="https://github.com/ChesterYue/ohmyzsh-theme-passion"
PASSION_THEME="$HOME/.oh-my-zsh/themes/passion.zsh-theme"

if [ -f "$PASSION_THEME" ]; then
    warn "Тема passion уже установлена, пропускаем..."
else
    TMP_DIR=$(mktemp -d)
    git clone --depth=1 "$PASSION_REPO" "$TMP_DIR/passion"
    cp "$TMP_DIR/passion/passion.zsh-theme" "$PASSION_THEME"
    rm -rf "$TMP_DIR"
    log "Тема passion установлена → $PASSION_THEME"
fi

PLUGIN_DIR="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
if [ -d "$PLUGIN_DIR" ]; then
    warn "zsh-autosuggestions уже установлен, обновляем..."
    git -C "$PLUGIN_DIR" pull --quiet
else
    info "Клонируем zsh-autosuggestions..."
    git clone --depth=1 \
        https://github.com/zsh-users/zsh-autosuggestions.git \
        "$PLUGIN_DIR"
    log "zsh-autosuggestions установлен"
fi

PLUGIN_DIR="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
if [ -d "$PLUGIN_DIR" ]; then
    warn "zsh-syntax-highlighting уже установлен, обновляем..."
    git -C "$PLUGIN_DIR" pull --quiet
else
    info "Клонируем zsh-syntax-highlighting..."
    git clone --depth=1 \
        https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$PLUGIN_DIR"
    log "zsh-syntax-highlighting установлен"
fi

ZSHRC="$HOME/.zshrc"

info "Настраиваем ~/.zshrc..."

cp "$ZSHRC" "${ZSHRC}.bak.$(date +%Y%m%d_%H%M%S)"
log "Резервная копия: ${ZSHRC}.bak.*"

if grep -q '^ZSH_THEME=' "$ZSHRC"; then
    if [ "$OS" = "Darwin" ]; then
        sed -i '' 's|^ZSH_THEME=.*|ZSH_THEME="passion"|' "$ZSHRC"
    else
        sed -i 's|^ZSH_THEME=.*|ZSH_THEME="passion"|' "$ZSHRC"
    fi
else
    echo 'ZSH_THEME="passion"' >> "$ZSHRC"
fi
log "Тема установлена: passion"

PLUGINS_LINE='plugins=(git sudo zsh-autosuggestions history-substring-search zsh-syntax-highlighting)'

if grep -q '^plugins=' "$ZSHRC"; then
    if [ "$OS" = "Darwin" ]; then
        sed -i '' "s|^plugins=.*|$PLUGINS_LINE|" "$ZSHRC"
    else
        sed -i "s|^plugins=.*|$PLUGINS_LINE|" "$ZSHRC"
    fi
else
    echo "$PLUGINS_LINE" >> "$ZSHRC"
fi
log "Плагины настроены"

if [ "$OS" = "Darwin" ]; then
    CURRENT_SHELL=$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')
else
    CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
fi
ZSH_PATH=$(which zsh)

if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
    warn "zsh уже является shell по умолчанию"
else
    info "Меняем shell по умолчанию на zsh..."
    chsh -s "$ZSH_PATH"
    log "Shell по умолчанию: $ZSH_PATH"
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   Установка завершена успешно! 🎉        ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Тема:    ${CYAN}passion${NC}"
echo -e "  Плагины: ${CYAN}git sudo zsh-autosuggestions${NC}"
echo -e "           ${CYAN}history-substring-search zsh-syntax-highlighting${NC}"
echo ""
echo -e "  Перезайди в терминал или выполни:"
echo -e "  ${YELLOW}exec zsh${NC}"

