# Architektura

```text
przeglądarka ──HTTP:80──▶ panel PL (index.html, statyczny, busybox httpd)
       │                        ├─▶ cgi-bin/*.sh (yi-hack: status, get/set_config)
       │                        └─▶ iframe :1984/stream.html (go2rtc → h264grabber)
       │
       └─HTTPS▶ GitHub (VERSION, files.txt, pliki) ──POST──▶ cgi-bin/apply_update.sh
```

## Decyzje

- **Brak kompilacji na kamerkę.** Panel to czysty HTML+JS, zero zależności
  (ranne jQuery wyrzucone). Każde pole konfiguracji bierze się z istniejących
  endpointów yi-hack (`get_configs.sh`, `set_configs.sh`, `camera_settings.sh`).
- **go2rtc zamiast rRTSPServer.** Binarka go2rtc 1.9.14 jest już w yi-hack,
  daje WebRTC (niski lag w przeglądarce) i RTSP na `:554` równolegle.
  yi-hack domyślnie wyłącza jego API — patch `service.sh` włącza je na `:1984`.
- **h264grabber jest on-demand.** Producent startuje przy pierwszym konsumencie,
  dlatego watchdog sprawdza tylko proces go2rtc (inaczej restartuje w pętli).
- **Aktualizacja przez przeglądarkę.** Kamerka nie ma klienta HTTPS (busybox
  `wget` tylko HTTP), więc panel pobiera pliki z `raw.githubusercontent.com`
  (CORS: `*`) i wysyła je POST-em na własny skrypt CGI `apply_update.sh`,
  który zapisuje je na kartę SD z białej listy plików (`files.txt`).
- **Chmura/MQTT wycięte.** Stockowy init yi-hack startuje `cloud` i `mqttv4`
  niezależnie od flag — instalator gasi procesy, dodaje guarda w skryptach
  startowych i cron co minutę domyka `cloud` oraz pilnuje watchdoga
  (w trybie go2rtc stockowy `service.sh` go nie startuje przy boocie).

## Układ repo

| Ścieżka | Rola |
|---|---|
| `www/index.html` | panel (Podgląd, Stan, Ustawienia, Konserwacja, Aktualizacja) |
| `www/live.html` | samodzielna strona live (osadzony go2rtc) |
| `www/cgi-bin/apply_update.sh` | zapis plików aktualizacji na SD (biała lista) |
| `www/VERSION`, `www/files.txt` | wersja panelu i manifest plików do aktualizacji |
| `sd/debug.sh` | hook na root karty SD — yi-hack go sam wykrywa i odpala co boot |
| `sd/yhcam/yhcam_install.sh` | właściwy (samo)instalator, wołany z `debug.sh` lub przez SSH |
| `scripts/install.sh` | instalator sieciowy (Linux/macOS/Windows+PuTTY) — wgrywa `sd/` i woła `yhcam_install.sh` |
| `scripts/uninstall.sh` | woła `sd/yhcam/uninstall.sh` zdalnie — powrót do panelu yi-hack |
