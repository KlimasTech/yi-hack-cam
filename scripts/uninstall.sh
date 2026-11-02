#!/bin/sh
# uninstall.sh — cofa yi-hack-cam do stanu yi-hack (odtwarza zachowane pliki).
# Uruchomienie: CAM_HOST=ADRES_KAMERY ./uninstall.sh
# Odpala TEN SAM sd/yhcam/uninstall.sh co przy deinstalacji z karty SD.
set -e
CAM_HOST="${CAM_HOST:?podaj CAM_HOST}"
CAM_USER="${CAM_USER:-root}"
OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=15"
rem() { ssh $OPTS "$CAM_USER@$CAM_HOST" "$1"; }
rem "[ -x /tmp/sd/yhcam/uninstall.sh ] && sh /tmp/sd/yhcam/uninstall.sh || echo 'brak /tmp/sd/yhcam/uninstall.sh — nic do zdjecia'"
