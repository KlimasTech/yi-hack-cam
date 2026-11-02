#!/bin/sh
# backup.sh — zrzuca WSZYSTKIE partycje flash kamery (mtdblock0-7) do
# /tmp/sd/backup/ na kamerce, a potem sciaga je lokalnie do backups/.
# To jest material potrzebny do odzyskania kamery (docs/UNBRICK.md) —
# bez tego backupu "miekki" unbrick nie jest mozliwy (tylko "trudny"
# przez UART, i to tylko jesli bootloader zyje).
# Uruchomienie: CAM_HOST=ADRES_KAMERY ./backup.sh
set -e
CAM_HOST="${CAM_HOST:?podaj CAM_HOST, np. CAM_HOST=ADRES_KAMERY ./backup.sh}"
CAM_USER="${CAM_USER:-root}"
CAM_PW="${CAM_PW:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"
OUT="$ROOT/backups/$CAM_HOST/$STAMP"

if command -v plink.exe >/dev/null 2>&1 || [ -x "/c/Program Files/PuTTY/plink.exe" ]; then
  PLINK="/c/Program Files/PuTTY/plink.exe"
  PSCP="/c/Program Files/PuTTY/pscp.exe"
  if [ -n "$CAM_PW" ]; then PWFILE="$(mktemp)"; printf '%s' "$CAM_PW" > "$PWFILE"
    PWFILE_W="$(cygpath -w "$PWFILE" 2>/dev/null || echo "$PWFILE")"
    AUTH="-pwfile $PWFILE_W"; else AUTH="-batch"; fi
  rem() { "$PLINK" -ssh $AUTH "$CAM_USER@$CAM_HOST" "$1"; }
  get() { "$PSCP" $AUTH -batch "$CAM_USER@$CAM_HOST:$1" "$2"; }
else
  OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=15"
  [ -n "$CAM_PW" ] && { echo "ustaw klucz SSH albo wypelnij CAM_PW tylko z plink (Windows)"; exit 1; }
  rem() { ssh $OPTS "$CAM_USER@$CAM_HOST" "$1"; }
  get() { scp $OPTS "$CAM_USER@$CAM_HOST:$1" "$2"; }
fi

MODEL="$(rem 'cat /tmp/sd/yi-hack/model_suffix 2>/dev/null' | tr -d '\r\n')"
echo "== model kamery: ${MODEL:-nieznany} =="

echo "== 1/2 dd mtdblock0-7 na kamerce (/tmp/sd/backup/) =="
rem "mkdir -p /tmp/sd/backup; \
  for i in 0 1 2 3 4 5 6 7; do \
    dd if=/dev/mtdblock\$i of=/tmp/sd/backup/mtdblock\$i.bin 2>/dev/null; \
  done; \
  cat /proc/mtd > /tmp/sd/backup/mtd.txt; \
  cp /home/homever /tmp/sd/backup/homever.txt 2>/dev/null; \
  ls -la /tmp/sd/backup/"

echo "== 2/2 sciaganie lokalnie do $OUT =="
mkdir -p "$OUT"
for i in 0 1 2 3 4 5 6 7; do
  get "/tmp/sd/backup/mtdblock$i.bin" "$OUT/mtdblock$i.bin"
done
get "/tmp/sd/backup/mtd.txt" "$OUT/mtd.txt"
get "/tmp/sd/backup/homever.txt" "$OUT/homever.txt" 2>/dev/null || true
echo "${MODEL:-nieznany}" > "$OUT/model_suffix.txt"

echo "GOTOWE: $OUT"
echo "Do 'miekkiego' unbricku (docs/UNBRICK.md) potrzebujesz mtdblock2.bin (rootfs),"
echo "mtdblock3.bin (home) i mtdblock4.bin (backup) z tego katalogu."
