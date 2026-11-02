#!/bin/sh
# watermark.sh — CGI: wgrywanie własnego znaku wodnego (BMP).
# Plik trafia do /tmp/sd/yi-hack/etc/watermark/custom.bmp i nadpisuje
# blank.bmp, który yi-hack montuje w miejsce wbudowanego logo (CUSTOM_WATERMARK).
# Zmiana widoczna po restarcie kamery.
YI="/tmp/sd/yi-hack"
WMDIR="$YI/etc/watermark"
json()  { printf "Content-type: application/json\r\n\r\n{\"error\":\"%s\"}\n" "$1"; }
jsons() { printf "Content-type: application/json\r\n\r\n{\"error\":\"%s\",\"custom\":\"%s\"}\n" "$1" "$2"; }

case "$QUERY_STRING" in
  action=status)
    [ -f "$WMDIR/custom.bmp" ] && jsons "false" "yes" || jsons "false" "no"; exit ;;
  action=reset)
    [ -f "$WMDIR/blank.yhcam.orig" ] && cp "$WMDIR/blank.yhcam.orig" "$WMDIR/blank.bmp"
    rm -f "$WMDIR/custom.bmp"
    json "false"; exit ;;
  action=upload) ;;
  *) json "true"; exit ;;
esac

mkdir -p "$WMDIR"
F="$WMDIR/upload.tmp"
cat > "$F"
SZ=${CONTENT_LENGTH:-0}
case "$SZ" in ''|*[!0-9]*|0) rm -f "$F"; json "true"; exit ;; esac
[ "$SZ" -gt 65536 ] && { rm -f "$F"; json "true"; exit; }
MAGIC=$(/tmp/sd/yi-hack/bin/busybox od -An -c -N2 "$F" 2>/dev/null || od -An -c -N2 "$F" 2>/dev/null)
case "$MAGIC" in *"B"*"M"*) ;; *) rm -f "$F"; json "true"; exit ;; esac
[ -f "$WMDIR/blank.yhcam.orig" ] || cp "$WMDIR/blank.bmp" "$WMDIR/blank.yhcam.orig"
mv "$F" "$WMDIR/custom.bmp"
cp "$WMDIR/custom.bmp" "$WMDIR/blank.bmp"
json "false"
