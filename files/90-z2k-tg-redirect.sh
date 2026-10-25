#!/bin/sh
# Delivered to this live NDM directory by the release install_map.
# /opt/etc/ndm/netfilter.d/90-z2k-tg-redirect.sh
export PATH=/opt/sbin:/opt/bin:/sbin:/usr/sbin:/bin:/usr/bin

[ "$type" = "ip6tables" ] && exit 0
[ "$table" = "nat" ] || exit 0

CONFIG_FILE="/opt/zapret2/config"
if [ -f "$CONFIG_FILE" ]; then
    user_disabled=$(awk -F= '/^TG_PROXY_USER_DISABLED=/ {gsub(/[" ]/,"",$2); print $2; exit}' "$CONFIG_FILE")
    if [ "$user_disabled" = "1" ]; then
        exit 0
    fi
fi

pidof tg-mtproxy-client >/dev/null 2>&1 || exit 0

LIB="/opt/zapret2/z2k-tg-redirect.sh"
[ -r "$LIB" ] || exit 0
. "$LIB"

z2k_tg_remove_legacy_rules
z2k_tg_ensure_rules
z2k_tg_flush_conntrack

exit 0
