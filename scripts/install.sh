#!/bin/sh
# install.sh — instalator yi-hack-cam na kamerkę Yi (Allwinner, yi-hack).
# Uruchomienie: CAM_HOST=ADRES_KAMERY ./install.sh
# Zakłada: yi-hack na karcie SD, dostęp root po SSH (hasło lub klucz).
# Skalnia: plink/pscp (Windows, PuTTY) albo scp/ssh (Linux/macOS).
set -e
CAM_HOST="${CAM_HOST:?podaj CAM_HOST, np. CAM_HOST=ADRES_KAMERY ./install.sh}"
CAM_USER="${CAM_USER:-root}"
CAM_PW="${CAM_PW:-}"
YI="/tmp/sd/yi-hack"
WWW="$YI/www"

if command -v plink.exe >/dev/null 2>&1 || [ -x "/c/Program Files/PuTTY/plink.exe" ]; then
  PLINK="/c/Program Files/PuTTY/plink.exe"
  PSCP="/c/Program Files/PuTTY/pscp.exe"
  if [ -n "$CAM_PW" ]; then PWFILE="$(mktemp)"; printf '%s' "$CAM_PW" > "$PWFILE"
    PWFILE_W="$(cygpath -w "$PWFILE" 2>/dev/null || echo "$PWFILE")"
    AUTH="-pwfile $PWFILE_W"; else AUTH="-batch"; fi
  rem() { "$PLINK" -ssh $AUTH "$CAM_USER@$CAM_HOST" "$1"; }
  put() { "$PSCP" $AUTH -batch "$1" "$CAM_USER@$CAM_HOST:$2"; }
else
  OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=15"
  [ -n "$CAM_PW" ] && { echo "ustaw klucz SSH albo wypelnij CAM_PW tylko z plink (Windows)"; exit 1; }
  rem() { ssh $OPTS "$CAM_USER@$CAM_HOST" "$1"; }
  put() { scp $OPTS "$1" "$CAM_USER@$CAM_HOST:$2"; }
fi

echo "== 1/6 pliki panelu =="
TMP="$(mktemp -d)"
cp www/index.html www/live.html www/VERSION www/files.txt "$TMP/"
put "$TMP/index.html" "$WWW/index.html"
put "$TMP/live.html" "$WWW/live.html"
put "$TMP/VERSION" "$WWW/VERSION"
put "$TMP/files.txt" "$WWW/files.txt"
put www/cgi-bin/apply_update.sh "$WWW/cgi-bin/apply_update.sh"

echo "== 2/6 usuniecie starego menu =="
rem "mkdir -p $YI/.oldui && cd $WWW && \
  for f in legacy.html.gz index.html.gz pages css js img onvif; do \
    [ -e \"\$f\" ] && mv \"\$f\" $YI/.oldui/ 2>/dev/null; done; \
  chmod 755 $WWW/cgi-bin/apply_update.sh; ls -la $WWW | head -20"

echo "== 3/6 konfiguracja systemowa (blokada chmury/MQTT/telnet) =="
rem "sed -i 's/^RTSP_ALT=.*/RTSP_ALT=go2rtc/; \
  s/^DISABLE_CLOUD=.*/DISABLE_CLOUD=yes/; \
  s/^REC_WITHOUT_CLOUD=.*/REC_WITHOUT_CLOUD=yes/; \
  s/^MQTT=.*/MQTT=no/; \
  s/^TELNETD=.*/TELNETD=no/' $YI/etc/system.conf; \
  grep -q CRONTAB= $YI/etc/system.conf && \
  sed -i 's|^CRONTAB=.*|CRONTAB=* * * * * killall cloud 2>/dev/null; ps \| grep -v grep \| grep -q wd.sh \|\| (sh /tmp/sd/yi-hack/script/wd.sh >/dev/null 2>\&1 \&)|' $YI/etc/system.conf; \
  grep -E '^(RTSP_ALT|DISABLE_CLOUD|REC_WITHOUT_CLOUD|MQTT|TELNETD|CRONTAB)=' $YI/etc/system.conf"

echo "== 4/6 patche skryptow yi-hack =="
rem "cd $YI/script && cp service.sh service.sh.pre-yhcam 2>/dev/null; \
  grep -q 'listen: \\\":1984\\\"' service.sh || \
  sed -i '0,/echo \"  listen: \\\"\\\"\" >> \/tmp\/go2rtc.yaml/s//echo \"  listen: \\\":1984\\\"\" >> \/tmp\/go2rtc.yaml/' service.sh; \
  grep -n 'listen' service.sh | head -4"

echo "== 5/6 wd.sh: go2rtc bez h264grabber, brak wskrzeszania MQTT =="
rem "cd $YI/script && cp wd.sh wd.sh.pre-yhcam 2>/dev/null; \
  grep -q 'NIE WSKRZESZAJ MQTT' wd.sh || \
  sed -i 's|^\\( *\\)if \\[ \"\$CPU1\" == \"\" \\] || \\[ \"\$CPU2\" == \"\" \\]; then\$|\\1# yi-hack-cam: h264grabber startuje on-demand\\n\\1if [ \"\$CPU2\" == \"\" ]; then|' wd.sh; \
  grep -q 'MQTT=no' wd.sh || \
  sed -i 's|^check_mqtt()$|check_mqtt()\\n{XX}|' wd.sh; true"

echo "== 6/6 restart uslug =="
rem "sh /tmp/sd/yi-hack/script/service.sh rtsp stop; sleep 2; \
  sh /tmp/sd/yi-hack/script/service.sh rtsp start; sleep 3; \
  killall -q telnetd; killall -q cloud; \
  ps | grep wd.sh | grep -v grep | awk '{print \$1}' | xargs kill 2>/dev/null; \
  sh $YI/script/wd.sh >/dev/null 2>&1 & sleep 3; \
  netstat -tlnp 2>/dev/null | grep -E '1984|554'; \
  free | head -2"
echo "ZAINSTALOWANO. Panel: http://$CAM_HOST/index.html"
