# Rozwiązywanie problemów

| Objaw | Przyczyna / naprawa |
|---|---|
| `/index.html` → 404 w `curl`, w przeglądarce OK | busybox httpd serwuje `.gz` tylko z nagłówkiem `Accept-Encoding: gzip` — curl go nie wysyła; to nie błąd |
| Stream stoi, „ładowanie…" | `netstat -tlnp \| grep 554` — jeśli słucha rRTSPServer zamiast go2rtc: `RTSP_ALT` nie jest `go2rtc`, zrestartuj RTSP (`service.sh rtsp stop/start`) |
| go2rtc restartuje się co ~20 s | watchdog wymaga h264grabber (startuje on-demand) — patch `wd.sh` z instalatora (sprawdzaj tylko go2rtc) |
| Po reboocie brak `wd.sh` | w trybie go2rtc stockowy `service.sh` go nie startuje — cron z instalatora to naprawia (`CRONTAB=` w system.conf) |
| `cloud`/`mqttv4` wróciły | cron dobija `cloud`; `mqttv4` blokuje patch `check_mqtt` — sprawdź, czy pliki na SD nie zostały nadpisane aktualizacją yi-hack |
| Aktualizacja z panelu: błąd zapisu pliku | `apply_update.sh` zapisuje tylko pliki z białej listy; sprawdź `files.txt` i prawa zapisu na SD |
| Kamera muli / restartuje się (OOM) | RAM to 60 MB; kandydaci do zdjęcia: `dispatch`, `pure-ftpd`, `telnetd` (już wyłączony); WebRTC też kosztuje — nie trzymaj otwartego streamu na stałe |
| Brak dostępu po ustawieniu statycznego IP | wejdź po DHCP (adres z routera) i popraw `STATIC_*` — puste = DHCP |
| Zmiana portu panelu i brak strony | `HTTPD_PORT` działa po restarcie usługi HTTP; live.html/proxy zna port `:1984` na sztywno względem hosta |
