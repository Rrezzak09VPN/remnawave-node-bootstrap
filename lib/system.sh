#!/bin/bash
# lib/system.sh

SCRIPT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_LIB_DIR/common.sh"

update_system() {
    info "Обновление системы..."
    export DEBIAN_FRONTEND=noninteractive
    apt update -qq 2>&1 | tee -a "$LOG_FILE" >/dev/null || error "Ошибка apt update"
    apt upgrade -y -qq 2>&1 | tee -a "$LOG_FILE" >/dev/null || error "Ошибка apt upgrade"
    apt autoremove -y -qq >/dev/null 2>&1 || true
    apt autoclean -qq >/dev/null 2>&1 || true
    ok "Система обновлена"
}

enable_bbr() {
    info "Настройка BBR..."
    if sysctl net.ipv4.tcp_congestion_control | grep -q bbr; then
        ok "BBR уже включен"
        return 0
    fi
    modprobe tcp_bbr 2>/dev/null || true
    echo "tcp_bbr" > /etc/modules-load.d/99-bbr.conf
    backup_file /etc/sysctl.conf
    if ! grep -q "Remnawave BBR" /etc/sysctl.conf; then
        cat >> /etc/sysctl.conf <<EOF

# Remnawave BBR
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
    fi
    sysctl --system >/dev/null 2>&1 || warn "Не удалось применить sysctl"
    if sysctl net.ipv4.tcp_congestion_control | grep -q bbr; then
        ok "BBR включен"
    else
        warn "BBR не включился (не критично)"
    fi
}
