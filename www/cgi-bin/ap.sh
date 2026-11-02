#!/bin/sh
# ap.sh — CGI: wlacznik trybu punktu dostepowego (AP) na wlan0.
# Uzywa hostapd + busybox-extras udhcpd (ARMv7/musl, zbudowane pod Alpine 3.12
# w kontenerze --platform linux/arm/v7, zeby dopasowac ABI do musl 1.1.x kamery).
# Akcje (?action=...): status | start | stop

YI_HACK_PREFIX=/tmp/sd/yi-hack
AP_BIN="$YI_HACK_PREFIX/bin"
AP_LIB="$YI_HACK_PREFIX/lib"
AP_SSID="YI-CAM"
AP_PASS="yicamkoneksja"
AP_IP="192.168.4.1"
AP_NETMASK="255.255.255.0"
AP_DHCP_START="192.168.4.100"
AP_DHCP_END="192.168.4.200"
WPA_CONF="/tmp/wpa_supplicant.conf"
STATE_FILE="/tmp/ap_mode.state"
HOSTAPD_CONF="/tmp/hostapd_ap.conf"
UDHCPD_CONF="/tmp/udhcpd_ap.conf"
LEASE_FILE="/tmp/udhcpd.leases"
LOG="/tmp/ap_mode.log"

json() { printf "Content-type: application/json\r\n\r\n%s\n" "$1"; }

cur_mode() { [ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo client; }

do_status() {
  json "{\"error\":\"false\",\"mode\":\"$(cur_mode)\",\"ssid\":\"$AP_SSID\",\"pass\":\"$AP_PASS\"}"
}

write_hostapd_conf() {
  cat > "$HOSTAPD_CONF" <<EOF
interface=wlan0
driver=nl80211
ssid=$AP_SSID
hw_mode=g
channel=6
wpa=2
wpa_passphrase=$AP_PASS
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
ctrl_interface=/tmp/hostapd_ctrl
EOF
}

write_udhcpd_conf() {
  cat > "$UDHCPD_CONF" <<EOF
start           $AP_DHCP_START
end             $AP_DHCP_END
interface       wlan0
lease_file      $LEASE_FILE
option subnet   $AP_NETMASK
option router   $AP_IP
option dns      $AP_IP
EOF
}

do_start() {
  if [ "$(cur_mode)" = "ap" ]; then json "{\"error\":\"false\",\"ssid\":\"$AP_SSID\",\"pass\":\"$AP_PASS\",\"note\":\"already running\"}"; exit; fi
  # Ustaw stan "ap" NAJPIERW — watchdog (wd.sh) sprawdza ten plik i pomija
  # restart WiFi/RTSP w tym trybie; bez tego wskrzesza go2rtc w kilka sekund.
  echo ap > "$STATE_FILE"
  # kamera ma tylko ok. 60 MB RAM — zwalniamy streaming (RTSP/go2rtc/h264grabber/
  # mp4record), zanim zaladujemy hostapd+libssl+libcrypto+libnl, inaczej OOM-killer
  # zabija procesy (sprawdzone: bez tego free spada do ~1.7 MB i hostapd pada).
  sh "$YI_HACK_PREFIX/script/service.sh" rtsp stop >/dev/null 2>&1
  killall -q -9 go2rtc h264grabber mp4record 2>/dev/null
  sleep 1
  killall -q -9 go2rtc h264grabber mp4record 2>/dev/null
  killall wpa_supplicant 2>/dev/null
  killall udhcpc 2>/dev/null
  sleep 1
  ifconfig wlan0 down
  ifconfig wlan0 "$AP_IP" netmask "$AP_NETMASK" up
  write_hostapd_conf
  write_udhcpd_conf
  LD_LIBRARY_PATH="$AP_LIB:/lib:/usr/lib" "$AP_BIN/hostapd" -B "$HOSTAPD_CONF" > "$LOG" 2>&1
  sleep 1
  if ! grep -q "AP-ENABLED" "$LOG"; then
    echo client > "$STATE_FILE"
    json "{\"error\":\"true\",\"msg\":\"hostapd nie wystartował: $(cat "$LOG" | tr '\n' ' ')\"}"
    exit
  fi
  "$AP_BIN/busybox-extras" udhcpd -f "$UDHCPD_CONF" > /tmp/udhcpd.log 2>&1 &
  json "{\"error\":\"false\",\"ssid\":\"$AP_SSID\",\"pass\":\"$AP_PASS\"}"
}

do_stop() {
  killall hostapd 2>/dev/null
  killall busybox-extras 2>/dev/null
  sleep 1
  ifconfig wlan0 down
  # Wyczysc stary staly adres z trybu AP (192.168.4.1) - "ifconfig down/up"
  # sam go NIE usuwa, wiec bez tego interfejs laczy sie jako klient do
  # prawdziwego AP, ale zostaje z poprzednim statycznym IP z trybu AP.
  ifconfig wlan0 0.0.0.0
  ifconfig wlan0 up
  /backup/tools/wpa_supplicant -c"$WPA_CONF" -g/var/run/wpa_supplicant-global -Dnl80211 -iwlan0 -B
  sleep 1
  udhcpc -i wlan0 -b -s /backup/tools/default.script
  echo client > "$STATE_FILE"
  # przywroc streaming wylaczony na czas AP
  sh "$YI_HACK_PREFIX/script/service.sh" rtsp start >/dev/null 2>&1 &
  json "{\"error\":\"false\"}"
}

case "${1:-$QUERY_STRING}" in
  *action=start*) do_start ;;
  *action=stop*)  do_stop ;;
  *)              do_status ;;
esac
