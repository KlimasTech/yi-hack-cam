#!/bin/sh
# wifi_qr.sh — CGI: zapis WiFi zeskanowanego z QR do partycji "conf".
# Metoda: identyczna jak stockowy configure_wifi.sh yi-hack
# (mtdblock7, offsety: SSID 28/64B, PSK 92/64B, bit polaczenia 24/4B).
# Wejscie: POST JSON {"ssid":"...","psk":"..."}, max 63 znaki.
# Odpowiedz: {"error":"false"|"true"}; przy ok zapisuje backup partycji na SD.
json()  { printf "Content-type: application/json\r\n\r\n{\"error\":\"%s\"}\n" "$1"; }

BODY=$(cat)
SSID=$(printf '%s' "$BODY" | grep -o '"ssid":"[^"]*"' | cut -d'"' -f4)
PSK=$(printf '%s' "$BODY" | grep -o '"psk":"[^"]*"' | cut -d'"' -f4)

case "$SSID" in ""|YOUR-WIFI-SSID) json "true"; exit ;; esac
[ ${#SSID} -gt 63 ] && { json "true"; exit; }
case "$PSK" in ""|YOUR-WIFI-PASSWORD) json "true"; exit ;; esac
[ ${#PSK} -gt 63 ] && { json "true"; exit; }

MTD=/dev/mtdblock7
[ -b "$MTD" ] || { json "true"; exit; }

DATE=$(date '+%Y%m%d%H%M%S')
dd if=$MTD of=/tmp/sd/mtdblock7_"$DATE".bin 2>/dev/null

cat /dev/zero | dd of=$MTD bs=1 seek=28 count=64 conv=notrunc 2>/dev/null
cat /dev/zero | dd of=$MTD bs=1 seek=92 count=64 conv=notrunc 2>/dev/null
printf '%s' "$SSID" | dd of=$MTD bs=1 seek=28 count=64 conv=notrunc 2>/dev/null
printf '%s' "$PSK"  | dd of=$MTD bs=1 seek=92 count=64 conv=notrunc 2>/dev/null
printf "\\00\\00\\00\\00" | dd of=$MTD bs=1 seek=24 count=4 conv=notrunc 2>/dev/null
sync; sync; sync
json "false"
