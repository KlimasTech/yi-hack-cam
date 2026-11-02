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
# Jedno zrodlo prawdy: wolamy PRAWDZIWY sd/yhcam/yhcam_install.sh (nie
# duplikujemy jego logiki tutaj - duplikat kiedys driftowal i zostal
# osobny, kruchy/zepsuty patch service.sh, ktory nigdy sie nie wykonywal
# na zywej kamerze; zob. historia commitow "FIX go2rtc API :1984").
YI="$WORK/card/yi-hack" sh "$ROOT/sd/yhcam/yhcam_install.sh"

echo "== 4/4 pakowanie (tar --mode wymusza +x niezaleznie od Windows/MSYS) =="
OUT="$DIST/yi-hack-cam-sd-full-${VERSION}-${BASE_MODEL}.tar.gz"
( cd "$WORK/card" && tar --mode='a+rwx' -czf "$OUT" . )
echo "GOTOWE: $OUT"
tar -tvzf "$OUT" | grep -E 'debug\.sh$|yhcam_install\.sh$|system\.sh$|busybox$' || true
