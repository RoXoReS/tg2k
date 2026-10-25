#!/bin/sh
# Установщик автономного Telegram-туннеля (вырезано из z2k)
# Репозиторий: https://github.com/RoXoReS/tg2k
REPO_RAW="https://raw.githubusercontent.com/RoXoReS/tg2k/main/files"

# Цвета для красивого вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Установка автономного Telegram-туннеля ===${NC}"

# 0. Проверка архитектуры
ARCH=$(uname -m)
if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ]; then
    echo -e "${RED}ОШИБКА: Этот установщик предназначен только для архитектуры ARM64 (aarch64).${NC}"
    echo -e "Ваша архитектура: ${YELLOW}$ARCH${NC}."
    echo "Установка прервана, чтобы не сломать систему."
    exit 1
fi
echo -e "${GREEN}-> Архитектура $ARCH поддерживается.${NC}"

# 1. Проверка и установка зависимостей
echo "-> Проверка зависимостей..."
NEED_INSTALL=0
for pkg in curl ipset iptables conntrack; do
    if ! command -v $pkg >/dev/null 2>&1; then
        echo -e "   ${YELLOW}Не найден: $pkg${NC}"
        NEED_INSTALL=1
    fi
done

if [ "$NEED_INSTALL" -eq 1 ]; then
    echo "-> Установка недостающих пакетов (opkg)..."
    opkg update
    opkg install curl ipset iptables conntrack
else
    echo -e "${GREEN}   Все зависимости на месте.${NC}"
fi

if ! command -v curl >/dev/null 2>&1; then
    echo -e "${RED}КРИТИЧЕСКАЯ ОШИБКА: curl не установлен, установка невозможна.${NC}"
    exit 1
fi

# 2. Создаем папки
echo "-> Создание каталогов..."
mkdir -p /opt/tg-only
mkdir -p /opt/zapret2
mkdir -p /opt/etc/ndm/netfilter.d/
mkdir -p /opt/etc/init.d/

# 3. Скачиваем основные файлы
echo "-> Загрузка файлов..."
for file in tg-mtproxy-client config z2k-roots.pem tg-tunnel-watchdog.sh z2k-tg-redirect.sh S98tg-tunnel; do
    echo "   Скачиваем $file..."
    if ! curl -fsSL "$REPO_RAW/$file" -o "/opt/tg-only/$file"; then
        echo -e "${RED}Ошибка скачивания $file${NC}"
        exit 1
    fi
done

# 4. Раскладываем по системным путям (для NDM-хука)
cp /opt/tg-only/z2k-tg-redirect.sh /opt/zapret2/
cp /opt/tg-only/config /opt/zapret2/
cp /opt/tg-only/S98tg-tunnel /opt/etc/init.d/

# 5. Скачиваем NDM-хук
echo "   Скачиваем NDM-хук..."
if ! curl -fsSL "$REPO_RAW/90-z2k-tg-redirect.sh" -o "/opt/etc/ndm/netfilter.d/90-z2k-tg-redirect.sh"; then
    echo -e "${RED}Ошибка скачивания NDM-хука${NC}"
    exit 1
fi

# 6. Выставляем права
echo "-> Настройка прав..."
chmod +x /opt/tg-only/tg-mtproxy-client
chmod +x /opt/tg-only/tg-tunnel-watchdog.sh
chmod +x /opt/tg-only/z2k-tg-redirect.sh
chmod +x /opt/etc/init.d/S98tg-tunnel
chmod +x /opt/etc/ndm/netfilter.d/90-z2k-tg-redirect.sh

# 7. Запускаем
echo "-> Запуск туннеля..."
/opt/etc/init.d/S98tg-tunnel start

echo -e "${GREEN}=== Установка завершена! ===${NC}"
# echo "Проверьте Telegram. Если он не работает:"
# echo "1. Проверьте конфиг: /opt/tg-only/config"
# echo "2. Перезапустите туннель: /opt/etc/init.d/S98tg-tunnel restart"