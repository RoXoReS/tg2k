#!/bin/sh
export PATH=/opt/sbin:/opt/bin:/sbin:/usr/sbin:/bin:/usr/bin

echo "Content-Type: text/plain"
echo ""

# Извлекаем чистую команду
ACTION=$(echo "$QUERY_STRING" | cut -d'&' -f1)

CONFIG="/opt/tg-only/config"
INIT="/opt/etc/init.d/S98tg-tunnel"
LOG="/tmp/z2k-log/tg-tunnel.log"
DEFAULT_URL="wss://85.192.60.175.nip.io/ws"

is_running() {
    for name in tg-mtproxy-client mtproxy tg-tunnel; do
        if pidof "$name" >/dev/null 2>&1; then return 0; fi
    done
    if netstat -tln 2>/dev/null | grep -q ":1443 "; then return 0; fi
    if ps w | grep -v grep | grep -q "tg-mtproxy"; then return 0; fi
    return 1
}

case "$ACTION" in
  status)
    if is_running; then echo "RUNNING"; else echo "STOPPED"; fi
    ;;
  start)
    if is_running; then echo "ERROR: Туннель уже запущен"; exit 0; fi
    if [ -f "$CONFIG" ]; then
        sed -i 's/^TG_PROXY_USER_DISABLED=.*/TG_PROXY_USER_DISABLED=0/' "$CONFIG"
    fi
    "$INIT" start >/dev/null 2>&1
    echo "OK: Туннель запущен"
    ;;
  stop)
    if ! is_running; then echo "ERROR: Туннель уже остановлен"; exit 0; fi
    if [ -f "$CONFIG" ]; then
        sed -i 's/^TG_PROXY_USER_DISABLED=.*/TG_PROXY_USER_DISABLED=1/' "$CONFIG"
    fi
    "$INIT" stop >/dev/null 2>&1
    echo "OK: Туннель остановлен"
    ;;
  logs)
    if [ -f "$LOG" ]; then tail -n 100 "$LOG"; else echo "Файл логов не найден"; fi
    ;;
  getaddr)
    if [ -f "$CONFIG" ]; then
        RELAY_URL=$(awk -F= '/^Z2K_RELAY_URL=/ {print $2; exit}' "$CONFIG" | tr -d '"' | tr -d "'")
        RELAY_SECRET=$(awk -F= '/^Z2K_RELAY_SECRET=/ {print $2; exit}' "$CONFIG" | tr -d '"' | tr -d "'")
        [ -z "$RELAY_URL" ] && RELAY_URL="$DEFAULT_URL"
        echo "URL:$RELAY_URL"
        echo "SECRET:$RELAY_SECRET"
    else
        echo "URL:$DEFAULT_URL"
        echo "SECRET:"
    fi
    ;;
  setaddr)
    # Декодируем URL
    RAW_URL=$(echo "$QUERY_STRING" | sed -n 's/.*addr=\([^&]*\).*/\1/p')
    NEW_URL=$(echo "$RAW_URL" | sed 's/%3A/:/g; s/%2F/\//g; s/%20/ /g; s/%2D/-/g; s/%5F/_/g; s/%2E/./g; s/%25/%/g')
    
    # Декодируем секрет
    RAW_SECRET=$(echo "$QUERY_STRING" | sed -n 's/.*secret=\([^&]*\).*/\1/p')
    NEW_SECRET=$(echo "$RAW_SECRET" | sed 's/%3D/=/g; s/%2B/+/g; s/%2F/\//g; s/%20/ /g')

    # Если URL пустой, ставим дефолт
    [ -z "$NEW_URL" ] && NEW_URL="$DEFAULT_URL"
    
    # Если нет протокола, добавляем wss://
    case "$NEW_URL" in
        wss://*|ws://*|https://*|http://*) ;;
        *) NEW_URL="wss://$NEW_URL" ;;
    esac

    if [ -f "$CONFIG" ]; then
        # Обновляем URL
        if grep -q "^Z2K_RELAY_URL=" "$CONFIG"; then
            sed -i "s|^Z2K_RELAY_URL=.*|Z2K_RELAY_URL=$NEW_URL|" "$CONFIG"
        else
            echo "Z2K_RELAY_URL=$NEW_URL" >> "$CONFIG"
        fi

        # Обновляем секрет
        if [ -n "$NEW_SECRET" ]; then
            if grep -q "^Z2K_RELAY_SECRET=" "$CONFIG"; then
                sed -i "s|^Z2K_RELAY_SECRET=.*|Z2K_RELAY_SECRET=$NEW_SECRET|" "$CONFIG"
            else
                echo "Z2K_RELAY_SECRET=$NEW_SECRET" >> "$CONFIG"
            fi
        fi

        "$INIT" restart >/dev/null 2>&1
        echo "OK: Настройки сохранены. Туннель перезапущен."
    else
        echo "ERROR: Файл конфигурации не найден"
    fi
    ;;
  resetaddr)
    if [ -f "$CONFIG" ]; then
        if grep -q "^Z2K_RELAY_URL=" "$CONFIG"; then
            sed -i "s|^Z2K_RELAY_URL=.*|Z2K_RELAY_URL=$DEFAULT_URL|" "$CONFIG"
        else
            echo "Z2K_RELAY_URL=$DEFAULT_URL" >> "$CONFIG"
        fi
        "$INIT" restart >/dev/null 2>&1
        echo "OK: Адрес сброшен на дефолтный. Туннель перезапущен."
    else
        echo "ERROR: Файл конфигурации не найден"
    fi
    ;;
  ping)
    HOST=""
    if [ -f "$CONFIG" ]; then
        RELAY_URL=$(awk -F= '/^Z2K_RELAY_URL=/ {print $2; exit}' "$CONFIG" | tr -d '"' | tr -d "'")
        [ -z "$RELAY_URL" ] && RELAY_URL="$DEFAULT_URL"
        HOST=$(echo "$RELAY_URL" | sed -e 's|^[^/]*//||' -e 's|/.*$||' | cut -d':' -f1)
    fi

    if [ -n "$HOST" ]; then
        PING_OUT=$(ping -4 -c 3 -W 2 "$HOST" 2>/dev/null)
        AVG_FULL=$(echo "$PING_OUT" | grep "min/avg/max" | cut -d'=' -f2 | cut -d'/' -f2)
        if [ -n "$AVG_FULL" ]; then
            echo "OK: $(echo "$AVG_FULL" | cut -d'.' -f1) ms"
        else
            if echo "$PING_OUT" | grep -q "bytes from"; then echo "OK: OK"; else echo "ERROR: Сервер не отвечает"; fi
        fi
    else
        echo "ERROR: Нет хоста"
    fi
    ;;
  *)
    echo "ERROR: Неизвестная команда '$ACTION'"
    ;;
esac