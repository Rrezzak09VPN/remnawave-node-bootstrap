#!/bin/bash
set -Eeuo pipefail

echo -e "\033[0;36m[*] Инициализация установщика Remnawave...\033[0m"

REPO_RAW="https://raw.githubusercontent.com/Rrezzak09VPN/remnawave-node-bootstrap/main"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "$SCRIPT_DIR/lib/common.sh" ]]; then
    echo "[*] Скрипт запущен одной строкой. Загрузка библиотек..."
    export TMP_DIR=$(mktemp -d)
    mkdir -p "$TMP_DIR/lib"
    for f in common.sh system.sh network.sh fail2ban.sh docker.sh; do
        echo "  -> Скачивание lib/$f..."
        # Жесткие таймауты: 10 сек на коннект, 30 сек на скачивание. Больше никаких зависаний.
        if ! curl -fsSL --connect-timeout 10 --max-time 30 "$REPO_RAW/lib/$f" -o "$TMP_DIR/lib/$f"; then
            echo -e "\033[0;31m[ОШИБКА] Не удалось скачать lib/$f (проверьте интернет)\033[0m"
            exit 1
        fi
    done
    echo "[*] Библиотеки успешно загружены."
    SCRIPT_DIR="$TMP_DIR"
fi

source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/system.sh"
source "$SCRIPT_DIR/lib/network.sh"
source "$SCRIPT_DIR/lib/fail2ban.sh"
source "$SCRIPT_DIR/lib/docker.sh"

clear

cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║     ██████╗ ███████╗███╗   ███╗███╗   ██╗ █████╗ ██╗    ██╗      ║
║     ██╔══██╗██╔════╝████╗ ████║████╗  ██║██╔══██╗██║    ██║      ║
║     ██████╔╝█████╗  ██╔████╔██║██╔██╗ ██║███████║██║ █╗ ██║      ║
║     ██╔══██╗██╔══╝  ██║╚██╔╝██║██║╚██╗██║██╔══██║██║███╗██║      ║
║     ██║  ██║███████╗██║ ╚═╝ ██║██║ ╚████║██║  ██║╚███╔███╔╝      ║
║     ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝ ╚══╝╚══╝       ║
║                                                                  ║
║           Remnawave Node Bootstrap Installer v1.0                ║
║                      by Rezzosoft KVN                            ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF

echo ""
info "Автоматическая настройка сервера для ноды Remnawave"
info "Лог-файл: $LOG_FILE"
echo ""

check_root
check_ubuntu_version
check_internet
check_disk_space
check_ram
check_ports
check_existing_node

echo ""
ask "Продолжить установку? [y/N]: "
read -r answer
[[ "$answer" =~ ^[Yy]$ ]] || exit 0

echo ""
info "Настройка IPv6"
echo "1) Оставить включенным (рекомендуется)"
echo "2) Отключить"
echo ""
ask "Ваш выбор [1/2]: "
read -r ipv6_choice

echo ""

update_system
enable_bbr

case "$ipv6_choice" in
    2) disable_ipv6 ;;
    *) enable_ipv6 ;;
esac

configure_ufw
block_ping
configure_fail2ban
install_docker
setup_remnanode

echo ""
ok "Установка завершена!"
echo ""

ask "Перезагрузить сервер сейчас? [y/N]: "
read -r reboot_answer

if [[ "$reboot_answer" =~ ^[Yy]$ ]]; then
    echo ""
    for i in {10..1}; do
        echo -ne "\rПерезагрузка через $i сек... (Ctrl+C для отмены) "
        sleep 1
    done
    echo ""
    reboot
else
    warn "Не забудьте перезагрузить сервер позже командой: reboot"
fi
