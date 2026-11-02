#!/bin/sh
# yhcam_install.sh — instalator overlay yi-hack-cam (uruchamiany NA kamerce).
# Wywolywany automatycznie przez /tmp/sd/debug.sh na KAZDYM boocie (hook
# wbudowany w yi-hack), zanim system.sh odpali usługi — dlatego patche
# system.conf dzialaja juz na tym samym boocie, bez recznego restartu.
# Mozna tez odpalic recznie przez SSH (scripts/install.sh robi to po scp).
# Idempotentny: mozna uruchamiac wielokrotnie / co boot bez skutkow ubocznych.
YI="${YI:-/tmp/sd/yi-hack}"
# YI nadpisywalny przez env (uzywa tego scripts/build-full-card.sh przy
# budowaniu pelnego pakietu offline - jedno zrodlo prawdy zamiast
# duplikowania tej logiki w dwoch miejscach).
# busybox na tej kamerce NIE MA appletu 'dirname' - $(dirname "$0") wywala sie
# cicho (log: "dirname: not found"), SRC ladowal sie na bledna sciezke (cwd
# procesu), caly cp dalej failowal z "can't stat". Czyste rozwiniecie parametru
# w sh (bez zewnetrznego polecenia) dziala zawsze w ash/busybox.
case "$0" in
  */*) SRC="${0%/*}" ;;
  *)   SRC="." ;;
esac
log() { echo "[yhcam] $1"; }

[ -d "$YI" ] || { log "brak $YI — najpierw zainstaluj yi-hack"; exit 1; }

log "chmod +x na binarkach/skryptach bazowego yi-hack (FAT32 nie gwarantuje +x)"
for d in "$YI/bin" "$YI/sbin" "$YI/usr/bin" "$YI/usr/sbin" "$YI/usr/libexec" \
         "$YI/script" "$YI/www/cgi-bin" "$YI/www/onvif"; do
  [ -d "$d" ] && find "$d" -maxdepth 1 -type f ! -name '*.gz' -exec chmod 755 {} \; 2>/dev/null
done

log "kopia panelu na SD"
mkdir -p "$YI/.yhcam-bak" "$YI/www/cgi-bin"
cp -f "$SRC/www/index.html"    "$YI/www/index.html"
cp -f "$SRC/www/live.html"     "$YI/www/live.html"
cp -f "$SRC/www/VERSION"       "$YI/www/VERSION"
cp -f "$SRC/www/files.txt"     "$YI/www/files.txt"
cp -f "$SRC/www/cgi-bin/apply_update.sh" "$YI/www/cgi-bin/apply_update.sh"
cp -f "$SRC/www/cgi-bin/watermark.sh"    "$YI/www/cgi-bin/watermark.sh"
cp -f "$SRC/www/cgi-bin/ap.sh"           "$YI/www/cgi-bin/ap.sh"
chmod 755 "$YI/www/cgi-bin/apply_update.sh" "$YI/www/cgi-bin/watermark.sh" \
  "$YI/www/cgi-bin/ap.sh"

log "binarki tryb AP (hostapd/udhcpd ARMv7-musl)"
mkdir -p "$YI/bin" "$YI/lib"
cp -f "$SRC/bin/hostapd"        "$YI/bin/hostapd"
cp -f "$SRC/bin/busybox-extras" "$YI/bin/busybox-extras"
cp -f "$SRC/lib/libnl-3.so.200"      "$YI/lib/libnl-3.so.200"
cp -f "$SRC/lib/libnl-genl-3.so.200" "$YI/lib/libnl-genl-3.so.200"
cp -f "$SRC/lib/libssl.so.1.1"       "$YI/lib/libssl.so.1.1"
cp -f "$SRC/lib/libcrypto.so.1.1"    "$YI/lib/libcrypto.so.1.1"
chmod 755 "$YI/bin/hostapd" "$YI/bin/busybox-extras"

log "usuwanie starego menu (backup w .oldui)"
mkdir -p "$YI/.oldui"
cd "$YI/www" || exit 1
for f in legacy.html.gz index.html.gz index.html.gz.new pages css js img onvif; do
  [ -e "$f" ] && mv "$f" "$YI/.oldui/" 2>/dev/null
done

log "hook w system.sh yi-hack"
grep -q "yi-hack-cam hook" "$YI/script/system.sh" || {
  cp "$YI/script/system.sh" "$YI/.yhcam-bak/system.sh.bak"
  printf '\n# yi-hack-cam hook\nif [ -f /tmp/sd/yhcam/hook.sh ]; then\n  chmod 755 /tmp/sd/yhcam/hook.sh 2>/dev/null\n  sh /tmp/sd/yhcam/hook.sh\nfi\n' \
    >> "$YI/script/system.sh"
}

log "konfiguracja (chmura/MQTT/telnet off, go2rtc on)"
sed -i 's/^RTSP_ALT=.*/RTSP_ALT=go2rtc/; s/^DISABLE_CLOUD=.*/DISABLE_CLOUD=yes/;
  s/^REC_WITHOUT_CLOUD=.*/REC_WITHOUT_CLOUD=yes/; s/^MQTT=.*/MQTT=no/;
  s/^TELNETD=.*/TELNETD=no/' "$YI/etc/system.conf"
grep -q "killall cloud" "$YI/etc/system.conf" || \
  sed -i 's|^CRONTAB=.*|CRONTAB=* * * * * killall cloud 2>/dev/null; ps \| grep -v grep \| grep -q wd.sh \|\| (sh /tmp/sd/yi-hack/script/wd.sh >/dev/null 2>\&1 \&)|' \
  "$YI/etc/system.conf"

log "patch service.sh (go2rtc API na :1984)"
API_LINE="$(grep -n 'echo "api:" >>' "$YI/script/service.sh" | sed -n '1p' | cut -d: -f1)"
if [ -n "$API_LINE" ]; then
  L=$((API_LINE + 1))
  if sed -n "${L}p" "$YI/script/service.sh" | grep -q 'listen: \\"\\"'; then
    cp "$YI/script/service.sh" "$YI/.yhcam-bak/service.sh.bak"
    # sed 'Nc\...' (change) zamiast dopasowania cudzyslowow regexem - te
    # ostatnie bylo kruche (zagniezdzone \" nigdy sie nie dopasowywaly
    # poprawnie przez wielopoziomowe escapowanie) i NIGDY faktycznie nie
    # patchowalo pliku (potwierdzone na zywej kamerze - api zawsze puste).
    # Sed c\ samo konsumuje jeden poziom \ w tekscie zamiany, wiec \\\"
    # w zrodle daje \" w wyniku.
    sed -i "${L}c\\        echo \"  listen: \\\\\":1984\\\\\"\" >> /tmp/go2rtc.yaml" \
      "$YI/script/service.sh"
  fi
fi

log "gotowe — uruchomione z debug.sh: dziala juz na tym boocie / reboot odswieza"
