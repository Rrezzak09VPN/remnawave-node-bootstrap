# 🚀 Remnawave Node Bootstrap Installer

![Linux](https://img.shields.io/badge/Linux-Ubuntu%2024.04-orange)
![Docker](https://img.shields.io/badge/Docker-ready-blue)
![Status](https://img.shields.io/badge/status-production--ready-success)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

Автоматизированный bootstrap-скрипт для развертывания ноды Remnawave на чистом VPS (Ubuntu 24.04).

---

## ⚡ Быстрый запуск (1 команда)

```bash
bash <(curl -s https://raw.githubusercontent.com/USERNAME/REPO/main/install.sh)
```

> 📋 Просто скопируй команду и вставь в терминал VPS (Ubuntu 24.04)

---

---

## 📌 Возможности

Скрипт выполняет полностью автоматическую настройку сервера:

- 🛡️ Preflight-проверки (RAM, диск, root, порты, интернет)
- 🔄 Обновление системы (apt upgrade безопасно)
- ⚡ Включение BBR (ускорение TCP)
- 🔥 Настройка UFW firewall
- 🚫 Блокировка ping (ICMP)
- 🌐 Настройка IPv6 (опционально)
- 🔒 Установка fail2ban (защита SSH)
- 🐳 Установка Docker + Compose
- 📦 Развёртывание Remnawave node в `/opt/remnanode`

---

## ⚙️ Требования

| Параметр | Значение |
|----------|----------|
| OS | Ubuntu 24.04 LTS |
| RAM | 512 MB (рекомендуется 1GB+) |
| Disk | 5 GB свободного места |
| Access | root |
| Network | активное интернет-соединение |

⚠️ Обязательно: порты **2222 и 443 должны быть свободны**

---

## 🧠 Логика работы

Скрипт проходит 9 этапов:

1. Preflight-проверки системы  
2. Обновление пакетов  
3. Включение BBR  
4. Настройка firewall (UFW)  
5. Блокировка ICMP ping  
6. Конфигурация IPv6  
7. Установка fail2ban  
8. Установка Docker  
9. Развёртывание ноды  

---

## 📂 Структура после установки

| Файл / Директория | Назначение |
|-------------------|------------|
| /opt/remnanode/ | Рабочая директория ноды Remnawave |
| /opt/remnanode/docker-compose.yml | Конфигурация контейнера |
| /var/log/remnawave-bootstrap.log | Лог установки |
| /etc/fail2ban/jail.local | Конфигурация fail2ban |
| /etc/ufw/after.rules | Правила блокировки ICMP |



---

## 🖥️ Управление

### Проверить статус контейнера
```bash
docker ps
```

### Посмотреть логи
```bash
docker logs -f remnanode
```

### Перезапуск
```bash
cd /opt/remnanode
docker compose restart
```

---

## 🔄 Идемпотентность

Скрипт безопасно можно запускать повторно:

- уже выполненные шаги пропускаются  
- конфиги сохраняются с `.bak`  
- docker-compose автоматически бэкапится  

---

## 🗑️ Удаление

Полное удаление ноды:

```bash
systemctl stop docker
rm -rf /opt/remnanode
docker system prune -a
```

---

## 📊 Мониторинг установки

Лог установки:

```bash
tail -f /var/log/remnawave-bootstrap.log
```

---

## 👤 Автор

**Rrezzak09VPN**

GitHub: https://github.com/Rrezzak09VPN

---

## 📄 Лицензия

MIT License — используйте свободно в личных и коммерческих проектах.

---

## ⚠️ Disclaimer

Скрипт предоставляется "как есть".  
Автор не несёт ответственности за возможные проблемы, повреждение данных или неправильную конфигурацию сервера.

Рекомендуется использовать только на чистых VPS.

---

## ❤️ Community

Сделано для сикретнова чатика камунити Remnawave
