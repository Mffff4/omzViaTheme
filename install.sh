#!/usr/bin/env bash

set -e

OS="$(uname -s)"
case "$OS" in
    Darwin)  
        SED_EXT=""
        if [ "$(id -u)" -eq 0 ]; then
            err "На macOS нельзя запускать скрипт от пользователя root. Пожалуйста, запустите его от обычного пользователя."
        fi
        ;;
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

if [ "$OS" = "Linux" ]; then
    if ! command -v sudo >/dev/null 2>&1; then
        err "Для установки зависимостей нужен sudo. Установите sudo или запустите подготовку сервера от root."
    fi
    info "Проверяем доступ sudo (пароль потребуется один раз)..."
    sudo -v
fi

info "Устанавливаем зависимости (zsh, git, curl, vim, ca-certificates, gnupg)..."
if [ "$OS" = "Darwin" ]; then
    if ! command -v brew >/dev/null 2>&1; then
        warn "Homebrew не найден, устанавливаем..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >/dev/null 2>&1
    fi
    brew install zsh git curl coreutils vim gnupg >/dev/null 2>&1
elif [ "$OS" = "Linux" ]; then
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -qq
        sudo apt-get install -y zsh git curl vim ca-certificates gnupg >/dev/null
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y zsh git curl vim ca-certificates gnupg2 -q
    else
        err "Менеджер пакетов не поддерживается. Установите zsh, git, curl, vim и gnupg вручную."
    fi
fi
log "Базовые зависимости установлены"

if [ "$OS" = "Linux" ] && command -v apt-get >/dev/null 2>&1; then
    if command -v docker >/dev/null 2>&1; then
        log "Docker уже установлен, пропускаем"
    else
        info "Устанавливаем Docker Engine из официального репозитория..."
        sudo install -m 0755 -d /etc/apt/keyrings
        if [ ! -f /etc/apt/keyrings/docker.asc ]; then
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.asc
            sudo chmod a+r /etc/apt/keyrings/docker.asc
        fi
        . /etc/os-release
        ARCH=$(dpkg --print-architecture)
        CODENAME=${VERSION_CODENAME:-$UBUNTU_CODENAME}
        printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu %s stable\n' "$ARCH" "$CODENAME" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        sudo apt-get update -qq
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null
        log "Docker Engine установлен"
    fi
    if command -v docker >/dev/null 2>&1 && ! id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
        sudo usermod -aG docker "$USER"
        warn "Пользователь $USER добавлен в группу docker — перелогинься, чтобы запускать Docker без sudo"
    fi
fi

if [ -d "$HOME/.oh-my-zsh" ] && [ -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    warn "Oh My Zsh уже установлен (~/.oh-my-zsh), пропускаем..."
else
    if [ -d "$HOME/.oh-my-zsh" ]; then
        warn "Обнаружена недоустановленная или поврежденная папка .oh-my-zsh. Удаляем её..."
        rm -rf "$HOME/.oh-my-zsh"
    fi
    info "Устанавливаем Oh My Zsh (unattended)..."
    RUNZSH=no CHSH=no REMOTE="https://github.com/ohmyzsh/ohmyzsh.git" GIT_TERMINAL_PROMPT=0 \
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
    GIT_TERMINAL_PROMPT=0 git clone --depth=1 "$PASSION_REPO" "$TMP_DIR/passion"
    cp "$TMP_DIR/passion/passion.zsh-theme" "$PASSION_THEME"
    rm -rf "$TMP_DIR"
    log "Тема passion установлена → passion"
fi

PLUGIN_DIR="$ZSH_CUSTOM/plugins/zsh-autosuggestions"
if [ -d "$PLUGIN_DIR" ]; then
    log "zsh-autosuggestions уже установлен, пропускаем"
else
    info "Клонируем zsh-autosuggestions..."
    GIT_TERMINAL_PROMPT=0 git clone --depth=1 \
        https://github.com/zsh-users/zsh-autosuggestions.git \
        "$PLUGIN_DIR"
    log "zsh-autosuggestions установлен"
fi

PLUGIN_DIR="$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
if [ -d "$PLUGIN_DIR" ]; then
    log "zsh-syntax-highlighting уже установлен, пропускаем"
else
    info "Клонируем zsh-syntax-highlighting..."
    GIT_TERMINAL_PROMPT=0 git clone --depth=1 \
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
    if [ "$OS" = "Darwin" ]; then
        if ! grep -qxF "$ZSH_PATH" /etc/shells; then
            info "Добавляем $ZSH_PATH в /etc/shells..."
            echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
        fi
    fi
    if sudo chsh -s "$ZSH_PATH" "$USER"; then
        log "Shell по умолчанию: $ZSH_PATH"
    else
        err "Не удалось сменить shell. Проверь sudo-доступ и повтори: sudo chsh -s $ZSH_PATH $USER"
    fi
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

