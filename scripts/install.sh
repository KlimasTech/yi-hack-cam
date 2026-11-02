#!/bin/sh
# install.sh — instalator yi-hack-cam na kamerke Yi (Allwinner, yi-hack).
# Uruchomienie: CAM_HOST=ADRES_KAMERY ./install.sh
# Zaklada: yi-hack na karcie SD, dostep root po SSH (haslo lub klucz).
# Skalnia: plink/pscp (Windows, PuTTY) albo scp/ssh (Linux/macOS).
#
# Robi to samo co wgranie plikow z sd/ na karte SD + reboot (patrz
# docs/INSTALL-SD.md) — tylko przez siec, bez wyjmowania karty. Wgrywa
# cala zawartosc sd/ na karte (/tmp/sd/) i odpala TEN SAM instalator
# (sd/yhcam/yhcam_install.sh), zeby logika nie zyla w dwoch miejscach.
set -e
CAM_HOST="${CAM_HOST:?podaj CAM_HOST, np. CAM_HOST=ADRES_KAMERY ./install.sh}"
CAM_USER="${CAM_USER:-root}"
CAM_PW="${CAM_PW:-}"
YI="/tmp/sd/yi-hack"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if command -v plink.exe >/dev/null 2>&1 || [ -x "/c/Program Files/PuTTY/plink.exe" ]; then
  PLINK="/c/Program Files/PuTTY/plink.exe"
  PSCP="/c/Program Files/PuTTY/pscp.exe"
  if [ -n "$CAM_PW" ]; then PWFILE="$(mktemp)"; printf '%s' "$CAM_PW" > "$PWFILE"
    PWFILE_W="$(cygpath -w "$PWFILE" 2>/dev/null || echo "$PWFILE")"
    AUTH="-pwfile $PWFILE_W"; else AUTH="-batch"; fi
  rem() { "$PLINK" -ssh $AUTH "$CAM_USER@$CAM_HOST" "$1"; }
  put() { "$PSCP" $AUTH -batch -r "$1" "$CAM_USER@$CAM_HOST:$2"; }
else
  OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=15"
  [ -n "$CAM_PW" ] && { echo "ustaw klucz SSH albo wypelnij CAM_PW tylko z plink (Windows)"; exit 1; }
  rem() { ssh $OPTS "$CAM_USER@$CAM_HOST" "$1"; }
  put() { scp $OPTS -r "$1" "$CAM_USER@$CAM_HOST:$2"; }
fi

echo "== 1/3 wgrywanie plikow (sd/ -> /tmp/sd/) =="
rem "mkdir -p /tmp/sd/yhcam/bin /tmp/sd/yhcam/lib /tmp/sd/yhcam/www/cgi-bin"
put "$ROOT/sd/debug.sh" "/tmp/sd/debug.sh"
put "$ROOT/sd/yhcam/yhcam_install.sh" "/tmp/sd/yhcam/yhcam_install.sh"
put "$ROOT/sd/yhcam/hook.sh" "/tmp/sd/yhcam/hook.sh"
put "$ROOT/sd/yhcam/uninstall.sh" "/tmp/sd/yhcam/uninstall.sh"
put "$ROOT/sd/yhcam/bin" "/tmp/sd/yhcam/"
put "$ROOT/sd/yhcam/lib" "/tmp/sd/yhcam/"
put "$ROOT/sd/yhcam/www" "/tmp/sd/yhcam/"
rem "chmod 755 /tmp/sd/debug.sh /tmp/sd/yhcam/yhcam_install.sh /tmp/sd/yhcam/hook.sh \
  /tmp/sd/yhcam/uninstall.sh /tmp/sd/yhcam/bin/* /tmp/sd/yhcam/www/cgi-bin/*.sh"

echo "== 2/3 instalacja (sh /tmp/sd/yhcam/yhcam_install.sh) =="
rem "sh /tmp/sd/yhcam/yhcam_install.sh"

echo "== 3/3 restart uslug (kamera juz dziala, same pliki nie wystarcza) =="
rem "sh $YI/script/service.sh rtsp stop; sleep 2; \
  sh $YI/script/service.sh rtsp start; sleep 3; \
  killall -q telnetd; killall -q cloud; \
  ps | grep wd.sh | grep -v grep | awk '{print \$1}' | xargs kill 2>/dev/null; \
  sh /tmp/sd/yhcam/hook.sh >/dev/null 2>&1 & \
  sleep 3; \
  netstat -tlnp 2>/dev/null | grep -E '1984|554'; \
  free | head -2"
echo "ZAINSTALOWANO. Panel: http://$CAM_HOST/index.html"
echo "Kolejne aktualizacje: ta sama komenda (wgra nowe pliki i odpali instalator), albo"
echo "wsadz karte do innej kamerki/czytnika, podmien pliki w sd/ i zrestartuj (self-install z debug.sh)."
