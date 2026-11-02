# yi-hack-cam

Lekki, polski panel do kamerki Yi (Allwinner) z yi-hack — live z go2rtc, pełna
konfiguracja, aktualizacje prosto z GitHuba. Powstał, bo stockowy panel yi-hack
jest ciężki, po angielsku i trzyma martwe zakładki (PTZ, MQTT), a chmura Xiaomi
mimo wyłączenia dalej potrafiła się budzić.

## Szybki start

```bash
git clone https://github.com/KlimasTech/yi-hack-cam
cd yi-hack-cam
CAM_HOST=ADRES_KAMERY ./scripts/install.sh
```

Potem otwórz `http://ADRES_KAMERY/` — zobaczysz nowy panel. Live: zakładka Podgląd.

## Co instalator robi na kamerce

| Krok | Efekt |
|---|---|
| Pliki panelu | `index.html`, `live.html`, `VERSION`, `cgi-bin/apply_update.sh` w `/tmp/sd/yi-hack/www/` |
| Usuwa stare menu | `pages/`, `css/`, `js/`, `img/`, `legacy.html.gz` trafiają do backupu `.oldui/` |
| Tryb go2rtc | `RTSP_ALT=go2rtc`, API na `:1984` (patch `service.sh`) |
| Blokada chmury | `DISABLE_CLOUD=yes`, `REC_WITHOUT_CLOUD=yes`, cron dobija proces `cloud` |
| Bez MQTT/telnet | `MQTT=no`, `TELNETD=no` (proces gasi automatycznie), watchdog nie wskrzesza `mqttv4` |
| Watchdog | patch `wd.sh`: w trybie go2rtc sprawdza tylko go2rtc (h264grabber startuje on-demand) |

Wszystko przeżywa reboot (zmiany leżą na karcie SD). Powrót: `./scripts/uninstall.sh`.

## Dokumentacja

| Plik | Temat |
|---|---|
| [docs/INSTALL.md](docs/INSTALL.md) | instalacja krok po kroku, też ręcznie bez skryptu |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | dlaczego tak to działa (go2rtc, CGI, aktualizacje z GitHuba) |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | typowe problemy i naprawy |

## Instalacja z karty SD (jak yi-hack)

1. Sformatuj kartę SD jako FAT32 (najlepiej sformatować w kamerce).
2. Pobierz ZIP z [Releases](https://github.com/KlimasTech/yi-hack-cam/releases)
   i wypakuj **zawartość** do katalogu głównego karty: katalog `yhcam/`
   (samoinstalator `yhcam-boot.sh`, patche `hook.sh`, deinstalator
   `uninstall.sh`, panel `www/`) oraz `README.md`, `LICENSE`, `wifi/`.
3. Włóż kartę do kamerki, zrestartuj ją i poczekaj ~1 minutę —
   overlay instaluje się sam przy pierwszym boocie (flaga wersji
   w `/tmp/sd/yi-hack/.yhcam-ver`, powtórki nic nie zmieniają).
4. Panel: `http://ADRES_KAMERKI/`.

**Jednorazowo (przy pierwszym użyciu czystej karty z działającym yi-hack):**
w `lower_half_init.sh` na karcie dopisz wiersz-hooka — szczegóły w
[docs/INSTALL-SD.md](docs/INSTALL-SD.md).

## Licencja

MIT, Copyright (c) 2026 KlimasTech.
