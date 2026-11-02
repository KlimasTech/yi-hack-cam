#!/bin/sh
# uninstall.sh — zdejmuje overlay (hook + pliki panelu), yi-hack zostaje.
YI="/tmp/sd/yi-hack"
echo "[yhcam] deinstalacja"
sed -i '/yi-hack-cam hook/d; /sh \/tmp\/sd\/yhcam\/hook.sh/d' "$YI/script/system.sh"
rm -f "$YI/www/index.html" "$YI/www/live.html" "$YI/www/VERSION" \
      "$YI/www/files.txt" "$YI/www/cgi-bin/apply_update.sh" \
      "$YI/www/cgi-bin/watermark.sh" "$YI/www/cgi-bin/ap.sh"
rm -f "$YI/bin/hostapd" "$YI/bin/busybox-extras" \
      "$YI/lib/libnl-3.so.200" "$YI/lib/libnl-genl-3.so.200" \
      "$YI/lib/libssl.so.1.1" "$YI/lib/libcrypto.so.1.1"
[ -d "$YI/.oldui" ] && mv "$YI/.oldui"/* "$YI/www/" 2>/dev/null
[ -f "$YI/.yhcam-bak/system.sh.bak" ] && cp "$YI/.yhcam-bak/system.sh.bak" "$YI/script/system.sh"
[ -f "$YI/.yhcam-bak/service.sh.bak" ] && cp "$YI/.yhcam-bak/service.sh.bak" "$YI/script/service.sh"
[ -f "$YI/.yhcam-bak/wd.sh.bak" ] && cp "$YI/.yhcam-bak/wd.sh.bak" "$YI/script/wd.sh"
[ -f "$YI/.yhcam-bak/wd.sh.bak2" ] && cp "$YI/.yhcam-bak/wd.sh.bak2" "$YI/script/wd.sh"
[ -f "$YI/.yhcam-bak/wd.sh.bak3" ] && cp "$YI/.yhcam-bak/wd.sh.bak3" "$YI/script/wd.sh"
rm -f /tmp/sd/debug.sh
echo "[yhcam] zdjeto (debug.sh usuniety, zeby nic sie juz nie doinstalowalo) — restart kamery"
