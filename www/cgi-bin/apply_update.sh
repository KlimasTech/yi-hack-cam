#!/bin/sh
# apply_update.sh — skrypt CGI na kamerce (yi-hack, busybox httpd).
# Przyjmuje body POST i zapisuje je do pliku z białej listy.
# Używa go zakładka "Aktualizacja" w panelu (przeglądarka pobiera pliki
# z GitHuba, bo kamerka nie ma klienta HTTPS).
YI="/tmp/sd/yi-hack/www"

# QUERY_STRING ma postać: file=sciezka/wzgledem/www
FILE=""
case "$QUERY_STRING" in
  file=*) FILE="${QUERY_STRING#file=}" ;;
esac

json() { printf "Content-type: application/json\r\n\r\n{\"error\":\"%s\"}\n" "$1"; }

case "$FILE" in
  index.html|live.html|VERSION|cgi-bin/apply_update.sh|cgi-bin/watermark.sh|cgi-bin/ap.sh) ;;
  *) json "true"; exit ;;
esac

cat > "$YI/$FILE.new.$$" && mv -f "$YI/$FILE.new.$$" "$YI/$FILE"
[ $? -eq 0 ] && json "false" || json "true"
