#!/bin/bash
# lib/network.sh

SCRIPT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_LIB_DIR/common.sh"

is_ipv6_disabled() {
    sysctl net.ipv6.conf.all.disable_ipv6 2>/dev/null | grep -q "= 1"
}

configure_ufw() {
    info "Настройка UFW..."
    
    local ssh_port
    ssh_port=$(get_ssh_port)
    
    command -v ufw >/dev/null 2>&1 || apt install -y ufw -qq >/dev/null 2>&1
    
    ufw --force disable >/dev/null 2>&1 || true
    
    if is_ipv6_disabled; then
        sed -i 's/^IPV6=.*/IPV6=no/' /etc/default/ufw
    else
        sed -i 's/^IPV6=.*/IPV6=yes/' /etc/default/ufw
    fi
    
    ufw default deny incoming >/dev/null
    ufw default allow outgoing >/dev/null
    ufw allow "${ssh_port}/tcp" >/dev/null
    ufw allow 2222/tcp >/dev/null
    ufw allow 443/tcp >/dev/null
    ufw --force enable >/dev/null || error "Не удалось включить UFW"
    
    ok "UFW настроен (порты: $ssh_port, 2222, 443)"
}

block_ping() {
    info "Блокировка ICMP ping..."
    
    local file="/etc/ufw/before.rules"
    local file6="/etc/ufw/before6.rules"
    
    backup_file "$file"
    backup_file "$file6"
    
    # IPv4: Меняем ACCEPT на DROP для echo-request
    sed -i '/echo-request/s/ACCEPT/DROP/' "$file"
    
    # IPv6: Меняем ACCEPT на DROP для echo-request (учтён синтаксис icmpv6)
    if [[ -f "$file6" ]]; then
        sed -i '/echo-request/s/ACCEPT/DROP/' "$file6"
    fi
    
    ufw reload >/dev/null 2>&1 || error "Не удалось перезагрузить UFW"
    ok "Ping заблокирован (IPv4/IPv6)"
}
disable_ipv6() {
    info "Отключение IPv6..."
    
    cat > /etc/sysctl.d/99-disable-ipv6.conf <<EOF
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
EOF
    
    sysctl -p /etc/sysctl.d/99-disable-ipv6.conf >/dev/null 2>&1 || warn "Не удалось применить настройки IPv6"
    ok "IPv6 отключен"
}

enable_ipv6() {
    info "IPv6 оставлен включенным"
    
    rm -f /etc/sysctl.d/99-disable-ipv6.conf
    sysctl --system >/dev/null 2>&1 || true
}
