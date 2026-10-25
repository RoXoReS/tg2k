#!/bin/sh
# Установщик автономного Telegram-туннеля (tg2k)
REPO_RAW="https://raw.githubusercontent.com/RoXoReS/tg2k/main/files"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Установка TG2K ===${NC}"

ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ]; then
    echo -e "${RED}ОШИБКА: Этот установщик предназначен только для ARM64.${NC}"
    echo -e "Ваша архитектура: ${YELLOW}$ARCH${NC}."
    exit 1
fi
echo -e "${GREEN}-> Архитектура $ARCH поддерживается.${NC}"

echo "-> Проверка зависимостей..."
NEED_INSTALL=0
for pkg in curl ipset iptables conntrack; do
    if ! command -v $pkg >/dev/null 2>&1; then
        echo -e "   ${YELLOW}Не найден: $pkg${NC}"
        NEED_INSTALL=1
    fi
done

if [ "$NEED_INSTALL" -eq 1 ]; then
    echo "-> Установка недостающих пакетов..."
    opkg update && opkg install curl ipset iptables conntrack
fi

if ! command -v curl >/dev/null 2>&1; then
    echo -e "${RED}КРИТИЧЕСКАЯ ОШИБКА: curl не установлен.${NC}"
    exit 1
fi

echo "-> Создание каталогов..."
mkdir -p /opt/tg-only
mkdir -p /opt/zapret2
mkdir -p /opt/etc/ndm/netfilter.d/
mkdir -p /opt/etc/init.d/

echo "-> Загрузка файлов..."
for file in tg-mtproxy-client config z2k-roots.pem tg-tunnel-watchdog.sh z2k-tg-redirect.sh S98tg-tunnel; do
    echo "   Скачиваем $file..."
    if ! curl -fsSL "$REPO_RAW/$file" -o "/opt/tg-only/$file"; then
        echo -e "${RED}Ошибка скачивания $file${NC}"
        exit 1
    fi
done

cp /opt/tg-only/z2k-tg-redirect.sh /opt/zapret2/
cp /opt/tg-only/config /opt/zapret2/
cp /opt/tg-only/S98tg-tunnel /opt/etc/init.d/

echo "   Скачиваем NDM-хук..."
if ! curl -fsSL "$REPO_RAW/90-z2k-tg-redirect.sh" -o "/opt/etc/ndm/netfilter.d/90-z2k-tg-redirect.sh"; then
    echo -e "${RED}Ошибка скачивания NDM-хука${NC}"
    exit 1
fi

echo "-> Настройка прав..."
chmod +x /opt/tg-only/tg-mtproxy-client
chmod +x /opt/tg-only/tg-tunnel-watchdog.sh
chmod +x /opt/tg-only/z2k-tg-redirect.sh
chmod +x /opt/etc/init.d/S98tg-tunnel
chmod +x /opt/etc/ndm/netfilter.d/90-z2k-tg-redirect.sh

echo "-> Запуск туннеля..."
/opt/etc/init.d/S98tg-tunnel start

# ==========================================
# Проверка наличия веб-панели
# ==========================================
WEB_PANEL_CONF="/opt/etc/lighttpd/conf.d/90-tg2k.conf"
if [ -f "$WEB_PANEL_CONF" ]; then
    echo "-> Обнаружена установленная веб-панель. Перезапускаем Lighttpd..."
    /opt/etc/init.d/S80lighttpd restart >/dev/null 2>&1
    echo -e "${GREEN}   Веб-панель готова к работе на порту 9090.${NC}"
fi

echo -e "${GREEN}=== Установка завершена! ===${NC}"