#!/bin/sh
export PATH=/opt/sbin:/opt/bin:/sbin:/usr/sbin:/bin:/usr/bin

echo "=== Удаление TG2K ==="

if [ "$(id -u)" -ne 0 ]; then
    echo "Ошибка: скрипт должен быть запущен от имени root."
    exit 1
fi

# ==========================================
# 1. Удаление веб-панели (если она установлена)
# ==========================================
LIGHTTPD_CONF="/opt/etc/lighttpd/conf.d/90-tg2k.conf"
WEB_DIR="/opt/share/www/tg2k"

if [ -f "$LIGHTTPD_CONF" ] || [ -d "$WEB_DIR" ]; then
    echo "-> Обнаружена веб-панель. Удаляем..."
    
    if [ -f "$LIGHTTPD_CONF" ]; then
        rm -f "$LIGHTTPD_CONF"
    fi
    
    if [ -d "$WEB_DIR" ]; then
        rm -rf "$WEB_DIR"
    fi
    
    # Перезапускаем Lighttpd, чтобы он отпустил порт
    if [ -x "/opt/etc/init.d/S80lighttpd" ]; then
        echo "-> Перезапуск Lighttpd..."
        /opt/etc/init.d/S80lighttpd restart >/dev/null 2>&1
    fi
else
    echo "-> Веб-панель не найдена, пропускаем..."
fi

# ==========================================
# 2. Удаление Telegram-туннеля
# ==========================================
echo "-> Остановка туннеля..."
if [ -f /opt/etc/init.d/S98tg-tunnel ]; then
    /opt/etc/init.d/S98tg-tunnel stop >/dev/null 2>&1
fi

echo "-> Остановка фоновых процессов..."
killall tg-tunnel-watchdog.sh 2>/dev/null
killall tg-mtproxy-client 2>/dev/null

echo "-> Удаление файлов туннеля..."
rm -rf /opt/tg-only
rm -rf /opt/zapret2
rm -f /opt/etc/init.d/S98tg-tunnel
rm -f /opt/etc/ndm/netfilter.d/90-z2k-tg-redirect.sh

echo "========================================"
echo "Удаление завершено! Все компоненты tg2k удалены."
echo "========================================"