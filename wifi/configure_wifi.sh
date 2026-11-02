#!/bin/sh
# configure_wifi.sh — wpisuje WiFi do pamieci kamery, tak samo jak yi-hack.
# Dane bierze z configure_wifi.cfg (ten sam format co yi-hack):
#   wifi_ssid=NAZWA-SIECI
#   wifi_psk=HASLO
#
# Sposob uzycia: wgraj oba pliki do KATALOGU GLOWNEGO karty SD (obok yhcam/),
# podmien wartosci w .cfg, wloz karte i zrestartuj kamerke.
# SSID i klucz ladują w partycji "conf" (/dev/mtdblock7), backup partycji
# zapisywany jest na karcie jako mtdblock7_RRRRMMDDGGMMSS.bin.
CFG_FILE="$(cd "$(dirname "$0")" && pwd)/configure_wifi.cfg"
[ -f "$CFG_FILE" ] || { echo "configure_wifi.cfg not found"; exit 1; }

SSID=$(grep ^wifi_ssid= "$CFG_FILE" | cut -d= -f2- | tr -d '\r')
KEY=$(grep ^wifi_psk= "$CFG_FILE" | cut -d= -f2- | tr -d '\r')

case "$SSID" in ""|YOUR-WIFI-SSID) echo "error: ustaw wifi_ssid w configure_wifi.cfg"; exit 1 ;; esac
[ ${#SSID} -gt 63 ] && { echo "error: ssid za dlugie"; exit 1; }
case "$KEY" in ""|YOUR-WIFI-PASSWORD) echo "error: ustaw wifi_psk w configure_wifi.cfg"; exit 1 ;; esac
[ ${#KEY} -gt 63 ] && { echo "error: haslo za dlugie"; exit 1; }

CURRENT_SSID=$(dd bs=1 skip=28 count=64 if=/dev/mtdblock7 2>/dev/null)
CURRENT_KEY=$(dd bs=1 skip=92 count=64 if=/dev/mtdblock7 2>/dev/null)
CONNECTED_BIT=$(hexdump -s 24 -n 4 -v /dev/mtdblock7 | awk 'FNR <=1' | awk '{print $3$2}')

echo "$SSID ${#SSID} - $CURRENT_SSID ${#CURRENT_SSID}"
echo "$KEY ${#KEY} - $CURRENT_KEY ${#CURRENT_KEY}"
echo "$CONNECTED_BIT"

if [ "$SSID" = "$CURRENT_SSID" ] && [ "$KEY" = "$CURRENT_KEY" ]; then
  echo "ssid i klucz juz zapisane"
  if [ "$CONNECTED_BIT" != "00000000" ]; then
    printf "\\00\\00\\00\\00" | dd of=/dev/mtdblock7 bs=1 seek=24 count=4 conv=notrunc
    sync; sync; sync
    reboot
  fi
  exit
fi

echo "backup partycji conf..."
DATE=$(date '+%Y%m%d%H%M%S')
dd if=/dev/mtdblock7 of=/tmp/sd/mtdblock7_"$DATE".bin 2>/dev/null

cat /dev/zero | dd of=/dev/mtdblock7 bs=1 seek=28 count=64 conv=notrunc
cat /dev/zero | dd of=/dev/mtdblock7 bs=1 seek=92 count=64 conv=notrunc
echo -n "$SSID" | dd of=/dev/mtdblock7 bs=1 seek=28 count=64 conv=notrunc
echo -n "$KEY" | dd of=/dev/mtdblock7 bs=1 seek=92 count=64 conv=notrunc
printf "\\00\\00\\00\\00" | dd of=/dev/mtdblock7 bs=1 seek=24 count=4 conv=notrunc

sync; sync; sync
reboot
