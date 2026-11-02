#!/bin/sh
# hook.sh — uruchamiany przez system.sh yi-hack przy kazdym boocie
# (po odpaleniu standardowych uslug). Naklada patche yi-hack-cam.
YI="/tmp/sd/yi-hack"
log() { echo "[yhcam-hook] $1"; }
mkdir -p "$YI/.yhcam-bak"
sleep 20

# 1. go2rtc API na :1984 (yi-hack domyslnie wylacza)
if ! grep -q 'listen: \\\":1984\\\"' "$YI/script/service.sh"; then
  log "patch service.sh (api :1984)"
  cp "$YI/script/service.sh" "$YI/.yhcam-bak/service.sh.bak"
  sed -i '0,/echo "  listen: \\\"\\\"" >> \/tmp\/go2rtc.yaml/s//echo "  listen: \\\":1984\\\"" >> \/tmp\/go2rtc.yaml/' \
    "$YI/script/service.sh"
fi

# 2. wd.sh: w trybie go2rtc sprawdzaj tylko go2rtc (h264grabber jest on-demand)
if grep -q '|| \[ "\$CPU2" == "" \]' "$YI/script/wd.sh"; then
  log "patch wd.sh (go2rtc)"
  cp "$YI/script/wd.sh" "$YI/.yhcam-bak/wd.sh.bak"
  sed -i 's/if \[ "\$CPU1" == "" \] || \[ "\$CPU2" == "" \]; then/if [ "\$CPU2" == "" ]; then/' \
    "$YI/script/wd.sh"
fi

# 3. wd.sh: nie wskrzesza mqttv4 przy MQTT=no
if ! grep -q 'yi-hack-cam: mqtt off' "$YI/script/wd.sh"; then
  log "patch wd.sh (mqtt off)"
  cp "$YI/script/wd.sh" "$YI/.yhcam-bak/wd.sh.bak2"
  awk '/^check_mqtt\(\)$/{print; print "    # yi-hack-cam: mqtt off"; \
    print "    if grep -qw \"MQTT=no\" /tmp/sd/yi-hack/etc/system.conf; then"; \
    print "        return"; print "    fi"; next}1' \
    "$YI/script/wd.sh" > /tmp/wd.new && mv /tmp/wd.new "$YI/script/wd.sh"
fi

# 4. dobij chmure i telnet, upewnij sie ze watchdog zyje
killall -q telnetd 2>/dev/null
killall -q cloud 2>/dev/null
if ! ps | grep -v grep | grep -q wd.sh; then
  log "start wd.sh"
  sh "$YI/script/wd.sh" >/dev/null 2>&1 &
fi
log "hook zakonczony"
