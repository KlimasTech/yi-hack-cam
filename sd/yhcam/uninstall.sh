#!/bin/sh
# uninstall.sh — zdejmuje overlay (hook + pliki panelu), yi-hack zostaje.
YI="/tmp/sd/yi-hack"
echo "[yhcam] deinstalacja"
sed -i '/yi-hack-cam hook/d; /sh \/tmp\/sd\/yhcam\/hook.sh/d' "$YI/script/system.sh"
rm -f "$YI/www/index.html" "$YI/www/live.html" "$YI/www/VERSION" \
      "$YI/www/files.txt" "$YI/www/cgi-bin/apply_update.sh"
[ -d "$YI/.oldui" ] && mv "$YI/.oldui"/* "$YI/www/" 2>/dev/null
[ -f "$YI/.yhcam-bak/service.sh.bak" ] && cp "$YI/.yhcam-bak/service.sh.bak" "$YI/script/service.sh"
[ -f "$YI/.yhcam-bak/wd.sh.bak" ] && cp "$YI/.yhcam-bak/wd.sh.bak" "$YI/script/wd.sh"
echo "[yhcam] zdjeto — restart kamery"
