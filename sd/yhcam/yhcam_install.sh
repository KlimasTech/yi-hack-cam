#!/bin/sh
# yhcam_install.sh — instalator overlay yi-hack-cam (uruchamiany NA kamerce).
# Kopiuje wierzch na karte SD i podpina hook w system.sh yi-hack.
# Idempotentny: mozna uruchamiac wielokrotnie.
YI="/tmp/sd/yi-hack"
SRC="$(cd "$(dirname "$0")" && pwd)"
log() { echo "[yhcam] $1"; }

[ -d "$YI" ] || { log "brak $YI — najpierw zainstaluj yi-hack"; exit 1; }

log "kopia panelu na SD"
mkdir -p "$YI/.yhcam-bak"
cp -f "$SRC/www/index.html"    "$YI/www/index.html"
cp -f "$SRC/www/live.html"     "$YI/www/live.html"
cp -f "$SRC/www/VERSION"       "$YI/www/VERSION"
cp -f "$SRC/www/files.txt"     "$YI/www/files.txt"
cp -f "$SRC/www/cgi-bin/apply_update.sh" "$YI/www/cgi-bin/apply_update.sh"
chmod 755 "$YI/www/cgi-bin/apply_update.sh"

log "usuwanie starego menu (backup w .oldui)"
mkdir -p "$YI/.oldui"
cd "$YI/www" || exit 1
for f in legacy.html.gz index.html.gz index.html.gz.new pages css js img; do
  [ -e "$f" ] && mv "$f" "$YI/.oldui/" 2>/dev/null
done

log "hook w system.sh yi-hack"
grep -q "yi-hack-cam hook" "$YI/script/system.sh" || {
  cp "$YI/script/system.sh" "$YI/.yhcam-bak/system.sh.bak"
  printf '\n# yi-hack-cam hook\nif [ -x /tmp/sd/yhcam/hook.sh ]; then\n  sh /tmp/sd/yhcam/hook.sh\nfi\n' \
    >> "$YI/script/system.sh"
}

log "konfiguracja (chmura/MQTT/telnet off, go2rtc on)"
sed -i 's/^RTSP_ALT=.*/RTSP_ALT=go2rtc/; s/^DISABLE_CLOUD=.*/DISABLE_CLOUD=yes/;
  s/^REC_WITHOUT_CLOUD=.*/REC_WITHOUT_CLOUD=yes/; s/^MQTT=.*/MQTT=no/;
  s/^TELNETD=.*/TELNETD=no/' "$YI/etc/system.conf"
grep -q "killall cloud" "$YI/etc/system.conf" || \
  sed -i 's|^CRONTAB=.*|CRONTAB=* * * * * killall cloud 2>/dev/null; ps \| grep -v grep \| grep -q wd.sh \|\| (sh /tmp/sd/yi-hack/script/wd.sh >/dev/null 2>\&1 \&)|' \
  "$YI/etc/system.conf"

log "gotowe — restart kamery aktywuje wszystko"
