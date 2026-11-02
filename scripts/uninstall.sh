#!/bin/sh
# uninstall.sh — cofa yi-hack-cam do stanu yi-hack (odtwarza zachowane pliki).
# Uruchomienie: CAM_HOST=ADRES_KAMERY ./uninstall.sh
set -e
CAM_HOST="${CAM_HOST:?podaj CAM_HOST}"
CAM_USER="${CAM_USER:-root}"
YI="/tmp/sd/yi-hack"
WWW="$YI/www"
OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=15"
rem() { ssh $OPTS "$CAM_USER@$CAM_HOST" "$1"; }
rem "cd $WWW && rm -f index.html live.html VERSION files.txt cgi-bin/apply_update.sh; \
  [ -d $YI/.oldui ] && mv $YI/.oldui/* $WWW/ 2>/dev/null; \
  [ -f $YI/script/service.sh.pre-yhcam ] && mv $YI/script/service.sh.pre-yhcam $YI/script/service.sh; \
  [ -f $YI/script/wd.sh.pre-yhcam ] && mv $YI/script/wd.sh.pre-yhcam $YI/script/wd.sh; \
  echo PRZYWROCONO; ls $WWW | head"
