# Instalacja

## Wymagania

- Kamerka Yi (Allwinner, np. y21ga) z kartą SD, na której działa yi-hack
  (v1 0.3.7 albo v2) — katalog `/tmp/sd/yi-hack` widoczny po SSH.
- Dostęp SSH jako root (domyślnie hasło puste).
- Komputer z `ssh`/`scp` (Linux/macOS) albo PuTTY `plink`/`pscp` (Windows).

## Instalacja skryptem

```bash
git clone https://github.com/KlimasTech/yi-hack-cam
cd yi-hack-cam
CAM_HOST=10.0.0.5 ./scripts/install.sh
```

Zmienne: `CAM_USER` (domyślnie `root`), `CAM_PW` (tylko z plink na Windows;
z OpenSSH użyj klucza). Na końcu instalator pokazuje link do panelu.

## Instalacja ręczna

1. Wgraj pliki z `www/` na kamerkę do `/tmp/sd/yi-hack/www/`
   (`index.html`, `live.html`, `VERSION`, `cgi-bin/apply_update.sh`).
2. Usuń stare menu: `pages/`, `css/`, `js/`, `img/`, `legacy.html.gz`
   (zrób wcześniej kopię, np. do `/tmp/sd/yi-hack/.oldui/`).
3. W `/tmp/sd/yi-hack/etc/system.conf` ustaw:
   `RTSP_ALT=go2rtc`, `DISABLE_CLOUD=yes`, `REC_WITHOUT_CLOUD=yes`,
   `MQTT=no`, `TELNETD=no` oraz dopisz do `CRONTAB=` wiersz:
   `killall cloud 2>/dev/null; ps | grep -v grep | grep -q wd.sh || (sh /tmp/sd/yi-hack/script/wd.sh >/dev/null 2>&1 &)`.
4. W `script/service.sh` zmień w sekcji go2rtc:
   `echo "  listen: \"\"" >> /tmp/go2rtc.yaml` (ta tuż po `echo "api:"`)
   na `echo "  listen: \":1984\"" >> /tmp/go2rtc.yaml`.
5. W `script/wd.sh` w funkcji `check_rtsp_go2rtc` zmień warunek
   `if [ "$CPU1" == "" ] || [ "$CPU2" == "" ]` na `if [ "$CPU2" == "" ]`
   (h264grabber startuje dopiero z pierwszym widzem).
6. W `script/wd.sh` w funkcji `check_mqtt` dodaj na początku:
   `if [[ $(get_config MQTT) != "yes" ]] ; then return; fi`.
7. W `script/system.sh` objąć warunkem `if [[ $(get_config MQTT) == "yes" ]]`
   linię `$START_STOP_SCRIPT mqtt start`.
8. Restart usług: `service.sh rtsp stop/start`, `killall telnetd cloud`,
   restart `wd.sh`, restart `crond` (busybox crond czyta crontab raz przy starcie).

## Weryfikacja

- `http://ADRES/` — nowy panel, zakładka Stan pokazuje dane kamery.
- `http://ADRES:1984/` — UI go2rtc, `stream.html?src=ch0_0.h264` gra.
- `ps | grep -E 'mqttv|cloud'` — pusto.
