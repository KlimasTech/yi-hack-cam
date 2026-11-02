#!/bin/sh
# build-full-card.sh — buduje SAMODZIELNY pakiet karty SD: bazowy yi-hack
# (roleoroleo/yi-hack-Allwinner-v2, MIT) + nasz overlay (sd/debug.sh,
# sd/yhcam/) zmergowane razem, gotowe do rozpakowania na CZYSTĄ kartę
# FAT32 bez żadnej wcześniejszej instalacji yi-hacka.
#
# Rożni się od docs/INSTALL-SD.md (ten zakłada już działający yi-hack na
# kamerze) — to jest pełny bundle dla kogoś, kto zaczyna od zera albo
# odzyskuje kamerę po utracie karty z działającym hackiem.
#
# Uzycie: BASE_MODEL=y211ga BASE_VERSION=0.3.7 ./scripts/build-full-card.sh
# Wynik: dist/yi-hack-cam-sd-full-<VERSION>-<BASE_MODEL>.tar.gz
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE_MODEL="${BASE_MODEL:-y211ga}"
BASE_VERSION="${BASE_VERSION:-0.3.7}"
VERSION="$(cat "$ROOT/www/VERSION")"
CACHE="$ROOT/.build-cache"
WORK="$ROOT/.build-work"
DIST="$ROOT/dist"
BASE_URL="https://github.com/roleoroleo/yi-hack-Allwinner-v2/releases/download/${BASE_VERSION}/${BASE_MODEL}_${BASE_VERSION}.tgz"
BASE_TGZ="$CACHE/${BASE_MODEL}_${BASE_VERSION}.tgz"

mkdir -p "$CACHE" "$DIST"
rm -rf "$WORK"
mkdir -p "$WORK/card"

echo "== 1/4 bazowy yi-hack ${BASE_MODEL} ${BASE_VERSION} (cache: $BASE_TGZ) =="
if [ ! -f "$BASE_TGZ" ]; then
  curl -sL --retry 3 -o "$BASE_TGZ" "$BASE_URL"
fi
mkdir -p "$WORK/base"
tar -xzf "$BASE_TGZ" -C "$WORK/base"
# Factory/ to jednorazowy instalator-patcher flasha (dd + hash check) -
# NIE dolaczamy go: zaklada czystego/stockowego hosta, a scenariusz "pelna
# karta" sluzy tez do odzysku kamery KTORA JUZ MA hack na flashu (patch
# /backup/init.sh juz tam jest) - ponowne puszczenie Factory/config.sh
# bylob y niepotrzebne (i przy roznym stanie hash moze sie nie udac).
cp -r "$WORK/base/yi-hack" "$WORK/card/yi-hack"
cp "$WORK/base/lower_half_init.sh" "$WORK/card/lower_half_init.sh"

echo "== 2/4 overlay yi-hack-cam (sd/debug.sh + sd/yhcam/) =="
cp "$ROOT/sd/debug.sh" "$WORK/card/debug.sh"
cp -r "$ROOT/sd/yhcam" "$WORK/card/yhcam"

echo "== 3/4 pre-apply overlay NA BUDOWANĄ karte (gotowe od pierwszego boota,"
echo "       debug.sh i tak go tez uruchomi co boot - idempotentny) =="
YI="$WORK/card/yi-hack" sh -c '
  YI="$1"; SRC="$2"
  . /dev/null
  set -e
  mkdir -p "$YI/.yhcam-bak" "$YI/www/cgi-bin"
  cp -f "$SRC/www/index.html" "$YI/www/index.html"
  cp -f "$SRC/www/live.html"  "$YI/www/live.html"
  cp -f "$SRC/www/VERSION"    "$YI/www/VERSION"
  cp -f "$SRC/www/files.txt"  "$YI/www/files.txt"
  cp -f "$SRC/www/cgi-bin/apply_update.sh" "$YI/www/cgi-bin/apply_update.sh"
  cp -f "$SRC/www/cgi-bin/watermark.sh"    "$YI/www/cgi-bin/watermark.sh"
  cp -f "$SRC/www/cgi-bin/ap.sh"           "$YI/www/cgi-bin/ap.sh"
  mkdir -p "$YI/bin" "$YI/lib"
  cp -f "$SRC/bin/hostapd"        "$YI/bin/hostapd"
  cp -f "$SRC/bin/busybox-extras" "$YI/bin/busybox-extras"
  cp -f "$SRC/lib/libnl-3.so.200"      "$YI/lib/libnl-3.so.200"
  cp -f "$SRC/lib/libnl-genl-3.so.200" "$YI/lib/libnl-genl-3.so.200"
  cp -f "$SRC/lib/libssl.so.1.1"       "$YI/lib/libssl.so.1.1"
  cp -f "$SRC/lib/libcrypto.so.1.1"    "$YI/lib/libcrypto.so.1.1"
  mkdir -p "$YI/.oldui"
  ( cd "$YI/www" && for f in legacy.html.gz index.html.gz index.html.gz.new pages css js img onvif; do
      [ -e "$f" ] && mv "$f" "$YI/.oldui/" 2>/dev/null
    done
  ) || true
  grep -q "yi-hack-cam hook" "$YI/script/system.sh" || \
    printf "\n# yi-hack-cam hook\nif [ -f /tmp/sd/yhcam/hook.sh ]; then\n  chmod 755 /tmp/sd/yhcam/hook.sh 2>/dev/null\n  sh /tmp/sd/yhcam/hook.sh\nfi\n" \
      >> "$YI/script/system.sh"
  sed -i "s/^RTSP_ALT=.*/RTSP_ALT=go2rtc/; s/^DISABLE_CLOUD=.*/DISABLE_CLOUD=yes/;
    s/^REC_WITHOUT_CLOUD=.*/REC_WITHOUT_CLOUD=yes/; s/^MQTT=.*/MQTT=no/;
    s/^TELNETD=.*/TELNETD=no/" "$YI/etc/system.conf"
  grep -q "killall cloud" "$YI/etc/system.conf" || \
    sed -i "s|^CRONTAB=.*|CRONTAB=* * * * * killall cloud 2>/dev/null; ps \\| grep -v grep \\| grep -q wd.sh \\|\\| (sh /tmp/sd/yi-hack/script/wd.sh >/dev/null 2>\\&1 \\&)|" \
      "$YI/etc/system.conf"
  if ! grep -q "listen: \\\\\":1984\\\\\"" "$YI/script/service.sh"; then
    sed -i "0,/echo \"  listen: \\\\\"\\\\\"\" >> \\/tmp\\/go2rtc.yaml/s//echo \"  listen: \\\\\":1984\\\\\"\" >> \\/tmp\\/go2rtc.yaml/" \
      "$YI/script/service.sh"
  fi
' _ "$WORK/card/yi-hack" "$ROOT/sd/yhcam"

echo "== 4/4 pakowanie (tar --mode wymusza +x niezaleznie od Windows/MSYS) =="
OUT="$DIST/yi-hack-cam-sd-full-${VERSION}-${BASE_MODEL}.tar.gz"
( cd "$WORK/card" && tar --mode='a+rwx' -czf "$OUT" . )
echo "GOTOWE: $OUT"
tar -tvzf "$OUT" | grep -E 'debug\.sh$|yhcam_install\.sh$|system\.sh$|busybox$' || true
