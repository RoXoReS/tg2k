#!/bin/sh
export PATH=/opt/sbin:/opt/bin:/sbin:/usr/sbin:/bin:/usr/bin
REPO_RAW="https://raw.githubusercontent.com/RoXoReS/tg2k/main/webpanel"

echo "=== Установка TG2K Web ==="

if [ "$(id -u)" -ne 0 ]; then
    echo "Ошибка: запустите от root."
    exit 1
fi

if ! command -v lighttpd >/dev/null 2>&1; then
    echo "Устанавливаем Lighttpd..."
    opkg update && opkg install lighttpd lighttpd-mod-cgi
fi

WEB_DIR="/opt/share/www/tg2k"
mkdir -p "$WEB_DIR"

echo "Скачиваем файлы панели..."
if ! curl -fsSL "$REPO_RAW/index.html" -o "$WEB_DIR/index.html"; then
    echo "Ошибка скачивания index.html"
    exit 1
fi
if ! curl -fsSL "$REPO_RAW/control.cgi" -o "$WEB_DIR/control.cgi"; then
    echo "Ошибка скачивания control.cgi"
    exit 1
fi
chmod +x "$WEB_DIR/control.cgi"

LIGHTTPD_CONF="/opt/etc/lighttpd/conf.d/90-tg2k.conf"
echo "Настраиваем Lighttpd на порт 9090..."
cat > "$LIGHTTPD_CONF" << 'EOF'
$SERVER["socket"] == ":9090" {
    server.document-root = "/opt/share/www/tg2k/"
    server.modules += ( "mod_cgi" )
    cgi.assign = ( ".cgi" => "/bin/sh" )
    index-file.names = ( "index.html" )
    setenv.set-environment = ( "PATH" => "/opt/sbin:/opt/bin:/opt/usr/sbin:/opt/usr/bin:/usr/sbin:/usr/bin:/sbin:/bin" )
}
EOF

echo "Перезапускаем Lighttpd..."
/opt/etc/init.d/S80lighttpd restart

IP_ADDR=$(ip -4 addr show br0 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
[ -z "$IP_ADDR" ] && IP_ADDR="<IP_РОУТЕРА>"

echo "========================================"
echo "Установка завершена!"
echo "Панель доступна: http://$IP_ADDR:9090"
echo "========================================"