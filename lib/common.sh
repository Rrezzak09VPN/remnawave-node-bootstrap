#!/bin/bash
set -Eeuo pipefail

SCRIPT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export CYAN='\033[0;36m'
export NC='\033[0m'

LOG_FILE="/var/log/remnawave-bootstrap.log"

cleanup() {
    rm -f /tmp/remnawave_install_* 2>/dev/null || true
    if [[ -n "${TMP_DIR:-}" && -d "${TMP_DIR:-}" ]]; then
        rm -rf "$TMP_DIR"
    fi
}
trap cleanup EXIT INT TERM

log() {
    local level=$1
    shift
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*" >> "$LOG_FILE"
}

ok() {
    echo -e "${GREEN}[OK]${NC} $*"
    log "OK" "$*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
    log "WARN" "$*"
}

info() {
    echo -e "${CYAN}[INFO]${NC} $*"
    log "INFO" "$*"
}

ask() {
    echo -e "${BLUE}[?]${NC} $*"
}

error() {
    echo -e "\n${RED}[ОШИБКА]${NC} $*" >&2
    log "ERROR" "$*"
    echo -e "${YELLOW}Установка прервана. Нажмите Enter для выхода...${NC}"
    read -r
    exit 1
}

backup_file() {
    local file=$1
    if [[ -f "$file" ]]; then
        local backup="${file}.bak.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        log "BACKUP" "Создан бэкап: $backup"
    fi
}

# Анимированный спиннер для долгих команд (apt, docker install)
run_with_spinner() {
    local cmd="$1"
    local msg="$2"
    local delay=0.1
    local spinstr='|/-\'
    local temp
    
    ( eval "$cmd" >> "$LOG_FILE" 2>&1 ) &
    local pid=$!
    
    while kill -0 "$pid" 2>/dev/null; do
        temp=${spinstr#?}
        printf "  [%c] %s" "$spinstr" "$msg"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\r\033[K"
    done
    
    wait "$pid"
    local exit_code=$?
    printf "\r\033[K"
    return $exit_code
}

check_root() {
    [[ $EUID -eq 0 ]] || error "Запустите скрипт от имени root (sudo)"
    ok "Root права есть"
}

check_ubuntu_version() {
    if [[ ! -f /etc/os-release ]]; then error "Не удалось определить ОС"; fi
    source /etc/os-release
    [[ "$ID" == "ubuntu" ]] || error "Поддерживается только Ubuntu"
    [[ "$VERSION_ID" == "24.04" ]] || error "Поддерживается только Ubuntu 24.04 (текущая: $VERSION_ID)"
    ok "Ubuntu 24.04 обнаружена"
}

check_internet() {
    if ! ping -c1 -W2 1.1.1.1 >/dev/null 2>&1; then
        if ! curl -fsS --max-time 5 https://1.1.1.1 >/dev/null 2>&1; then
            error "Нет доступа в интернет"
        fi
    fi
    getent hosts github.com >/dev/null 2>&1 || error "Не работает DNS (github.com)"
    ok "Интернет есть"
}

check_disk_space() {
    local free_gb
    free_gb=$(df / --output=avail | tail -1 | awk '{print int($1/1024/1024)}')
    [[ "$free_gb" -ge 3 ]] || error "Мало места на диске (нужно 3GB, есть ${free_gb}GB)"
    ok "Место на диске OK (${free_gb}GB свободно)"
}

check_ram() {
    local ram_mb
    ram_mb=$(free -m | awk '/^Mem:/{print $2}')
    if [[ "$ram_mb" -lt 512 ]]; then
        warn "Мало оперативной памяти: ${ram_mb}MB"
    else
        ok "ОЗУ: ${ram_mb}MB"
    fi
}

check_ports() {
    for port in 2222 443; do
        if ss -tln "( sport = :$port )" | grep -q LISTEN; then
            error "Порт ${port} уже занят другим сервисом"
        fi
    done
    ok "Порты 2222 и 443 свободны"
}

get_ssh_port() {
    local ssh_port
    ssh_port=$(sshd -T 2>/dev/null | awk '/^port /{print $2}' | head -1)
    echo "${ssh_port:-22}"
}

check_existing_node() {
    local node_found=false
    if [[ -f "/opt/remnanode/docker-compose.yml" ]]; then node_found=true; fi
    if command -v docker >/dev/null 2>&1; then
        if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx "remnanode"; then
            node_found=true
        fi
    fi
    if [[ "$node_found" == true ]]; then
        warn "ВНИМАНИЕ: Обнаружена уже установленная нода Remnawave!"
        echo "Этот скрипт предназначен для ЧИСТЫХ серверов."
        ask "Вы уверены, что хотите продолжить? [y/N]: "
        read -r answer
        if [[ ! "$answer" =~ ^[Yy]$ ]]; then
            info "Установка отменена."
            exit 0
        fi
    fi
}
