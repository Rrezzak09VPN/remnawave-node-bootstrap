#!/bin/bash
# lib/fail2ban.sh

SCRIPT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_LIB_DIR/common.sh"
source "$SCRIPT_LIB_DIR/network.sh"

configure_fail2ban() {
    info "Установка и настройка fail2ban..."
    local ssh_port
    ssh_port=$(get_ssh_port)
    command -v fail2ban-client >/dev/null 2>&1 || apt install -y fail2ban -qq >/dev/null 2>&1 || error "Не удалось установить fail2ban"
    backup_file /etc/fail2ban/jail.local
    local ipv6_setting=""
    if is_ipv6_disabled; then
        ipv6_setting="allowipv6 = no"
    fi
    cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 7d
findtime = 3m
maxretry = 3
backend = systemd
banaction = ufw
$ipv6_setting

[sshd]
enabled = true
mode = aggressive
port = $ssh_port
logpath = /var/log/auth.log
EOF
    systemctl enable fail2ban --now >/dev/null 2>&1 || error "Не удалось запустить fail2ban"
    ok "Fail2ban настроен (SSH порт: $ssh_port)"
}
