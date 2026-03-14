#!/usr/bin/env bash
# ============================================================
#  Oh-My-Zsh full setup: passion theme + plugins
#  Совместимо с Debian/Ubuntu
# ============================================================

set -e  # прерываться при ошибке

# ─── Цвета для вывода ────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
info() { echo -e "${CYAN}[→]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# ─── 1. Установка зависимостей ───────────────────────────────
info "Устанавливаем zsh, git, curl..."
sudo apt-get update -q
sudo apt-get install -y zsh git curl
log "Зависимости установлены"

# ─── 2. Установка Oh My Zsh ──────────────────────────────────
if [ -d "$HOME/.oh-my-zsh" ]; then
    warn "Oh My Zsh уже установлен, пропускаем..."
else
    info "Устанавливаем Oh My Zsh (unattended)..."
    RUNZSH=no CHSH=no \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        "" --unattended
    log "Oh My Zsh установлен"
fi

# Определяем директорию кастомизаций
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# ─── 3. Установка темы passion ───────────────────────────────
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

# На Linux тема требует date (GNU), на macOS нужен gdate (coreutils)
# На Debian/Ubuntu date уже поддерживает %N — всё ок

# ─── 4. Установка внешних плагинов ───────────────────────────

# zsh-autosuggestions
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

# zsh-syntax-highlighting
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

# git, sudo, history-substring-search — встроены в OMZ, клонировать не нужно

# ─── 5. Настройка ~/.zshrc ───────────────────────────────────
ZSHRC="$HOME/.zshrc"

info "Настраиваем ~/.zshrc..."

# Создаём резервную копию
cp "$ZSHRC" "${ZSHRC}.bak.$(date +%Y%m%d_%H%M%S)"
log "Резервная копия: ${ZSHRC}.bak.*"

# Устанавливаем тему
if grep -q '^ZSH_THEME=' "$ZSHRC"; then
    sed -i 's|^ZSH_THEME=.*|ZSH_THEME="passion"|' "$ZSHRC"
else
    echo 'ZSH_THEME="passion"' >> "$ZSHRC"
fi
log "Тема установлена: passion"

# Устанавливаем плагины
PLUGINS_LINE='plugins=(git sudo zsh-autosuggestions history-substring-search zsh-syntax-highlighting)'

if grep -q '^plugins=' "$ZSHRC"; then
    # Заменяем существующую строку plugins=
    sed -i "s|^plugins=.*|$PLUGINS_LINE|" "$ZSHRC"
else
    echo "$PLUGINS_LINE" >> "$ZSHRC"
fi
log "Плагины настроены"

# ─── 6. Меняем shell по умолчанию на zsh ─────────────────────
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
ZSH_PATH=$(which zsh)

if [ "$CURRENT_SHELL" = "$ZSH_PATH" ]; then
    warn "zsh уже является shell по умолчанию"
else
    info "Меняем shell по умолчанию на zsh..."
    chsh -s "$ZSH_PATH"
    log "Shell по умолчанию: $ZSH_PATH"
fi

# ─── Готово ──────────────────────────────────────────────────
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

