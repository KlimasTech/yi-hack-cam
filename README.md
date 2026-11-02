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
| Tryb AP | `hostapd`+`udhcpd` (ARMv7/musl) + `cgi-bin/ap.sh`, patch `wd.sh` (nie walczy z AP) |

Wszystko przeżywa reboot (zmiany leżą na karcie SD). Powrót: `./scripts/uninstall.sh`.

## Tryb punktu dostępowego (AP) — zakładka „Tryb AP”

Kamera może rozgłosić własną sieć WiFi **`YI-CAM`** (hasło `yicamkoneksja`,
zmień w `www/cgi-bin/ap.sh`), żeby skonfigurować ją bez dostępu do głównej
sieci — panel wtedy pod `http://192.168.4.1/`. Włącza się ręcznie (przycisk
w panelu) albo automatycznie, jeśli kamera nie złapie WiFi w ciągu 60 s po
boocie.

**Ograniczenie pamięci (ważne):** kamera ma tylko ~60 MB RAM, z czego ~40 MB
zajmuje stały proces firmware (`rmm`). `ap.sh` przed startem AP ubija
RTSP/go2rtc/h264grabber (inaczej OOM-killer zabija hostapd) i przywraca je
po wyłączeniu AP. W trybie AP streaming jest więc wyłączony.

**Jeśli coś pójdzie nie tak (AP się nie wyłącza, panel nieosiągalny):**
1. Połącz się z siecią `YI-CAM`, otwórz `http://192.168.4.1/cgi-bin/ap.sh?action=stop`.
2. Albo zrób power-cycle kamery — stan AP (`/tmp/ap_mode.state`) żyje w tmpfs
   i czyści się przy restarcie; kamera wraca do normalnego WiFi klienckiego.
3. Binarki (`hostapd`, `busybox-extras`/udhcpd, `libnl`/`libssl`/`libcrypto`)
   są zbudowane pod Alpine 3.12 (musl 1.1.24, armv7) żeby pasować do starego
   musl 1.1.16 kamery — nowszy Alpine (≥3.14, musl 1.2+) ma niekompatybilne
   ABI (symbole `*_time64`) i się nie odpali.

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
