#!/bin/bash
# lib/docker.sh

SCRIPT_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_LIB_DIR/common.sh"

install_docker() {
    info "Установка Docker..."
    if ! command -v docker >/dev/null 2>&1; then
        curl --fail --silent --show-error --location \
            --retry 3 \
            --connect-timeout 10 \
            https://get.docker.com \
            -o /tmp/get-docker.sh || error "Не удалось скачать установщик Docker"
        sh /tmp/get-docker.sh >/dev/null 2>&1 || error "Ошибка установки Docker"
        rm -f /tmp/get-docker.sh
    fi
    info "Ожидание запуска Docker daemon..."
    timeout 30 bash -c 'until docker info >/dev/null 2>&1; do sleep 1; done' || error "Docker daemon не запустился за 30 секунд"
    docker compose version >/dev/null 2>&1 || error "Docker Compose недоступен"
    ok "Docker готов к работе"
}

setup_remnanode() {
    info "Настройка Remnawave ноды..."
    local node_dir="/opt/remnanode"
    mkdir -p "$node_dir"
    if [[ -f "$node_dir/docker-compose.yml" ]]; then
        backup_file "$node_dir/docker-compose.yml"
    fi
    echo ""
    info "Вставьте содержимое docker-compose.yml из панели Remnawave."
    info "После вставки нажмите Ctrl+D для сохранения."
    echo "------------------------------------------------"
    cat > "$node_dir/docker-compose.yml"
    echo "------------------------------------------------"
    [[ -s "$node_dir/docker-compose.yml" ]] || error "Файл docker-compose.yml пуст"
    
    ( cd "$node_dir" && docker compose config >/dev/null 2>&1 ) || error "Ошибка валидации docker-compose.yml"
    
    echo ""
    ask "Запустить контейнер Remnawave сейчас? [Y/n]: "
    local answer
    read -r answer
    if [[ -z "$answer" || "$answer" =~ ^[Yy]$ ]]; then
        ( cd "$node_dir" && docker compose up -d ) || error "Не удалось запустить контейнеры"
        sleep 3
        if docker ps --format '{{.Names}}' | grep -qx "remnanode"; then
            ok "Контейнер remnanode успешно запущен"
        else
            warn "Контейнер не найден в списке запущенных. Проверьте: docker ps"
        fi
    else
        info "Запуск отменен. Запустить вручную: cd $node_dir && docker compose up -d"
    fi
}
