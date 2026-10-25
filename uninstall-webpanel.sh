#!/bin/sh
export PATH=/opt/sbin:/opt/bin:/sbin:/usr/sbin:/bin:/usr/bin

echo "=== Удаление TG2K Web Panel ==="

if [ "$(id -u)" -ne 0 ]; then
    echo "Ошибка: запустите от root."
    exit 1
fi

LIGHTTPD_CONF="/opt/etc/lighttpd/conf.d/90-tg2k.conf"
if [ -f "$LIGHTTPD_CONF" ]; then
    echo "Удаляем конфигурацию Lighttpd..."
    rm -f "$LIGHTTPD_CONF"
fi

WEB_DIR="/opt/share/www/tg2k"
if [ -d "$WEB_DIR" ]; then
    echo "Удаляем файлы панели..."
    rm -rf "$WEB_DIR"
fi

echo "Перезапускаем Lighttpd..."
/opt/etc/init.d/S80lighttpd restart

echo "Веб-панель успешно удалена."