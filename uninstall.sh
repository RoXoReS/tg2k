#!/bin/sh
# Скрипт полного удаления автономного Telegram-туннеля (tg2k)

echo "=== Удаление Telegram-туннеля ==="

# 1. Останавливаем туннель
if [ -f /opt/etc/init.d/S98tg-tunnel ]; then
    echo "-> Остановка туннеля..."
    /opt/etc/init.d/S98tg-tunnel stop
else
    echo "-> Скрипт запуска не найден, пропускаем..."
fi

# 2. Убиваем сторожа и оставшиеся процессы
echo "-> Остановка фоновых процессов..."
killall tg-tunnel-watchdog.sh 2>/dev/null
killall tg-mtproxy-client 2>/dev/null

# 3. Удаляем файлы
echo "-> Удаление файлов..."
rm -rf /opt/tg-only
rm -rf /opt/zapret2
rm -f /opt/etc/init.d/S98tg-tunnel
rm -f /opt/etc/ndm/netfilter.d/90-z2k-tg-redirect.sh

echo "=== Удаление завершено! ==="
echo "Все компоненты туннеля успешно удалены."