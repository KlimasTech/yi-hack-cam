# Przygotowanie karty SD (instalacja w stylu yi-hack)

## Jak to działa

yi-hack przy każdym boocie wykonuje `/tmp/sd/lower_half_init.sh` z karty SD.
Instalator yi-hack-cam dokleja do niego JEDEN warunkowy wiersz, który uruchamia
`/tmp/sd/yhcam/yhcam-boot.sh`. Od tego momentu działasz jak przy yi-hack:
**wypakowujesz pliki na kartę, restartujesz kamerkę i soft wgrywa się sam**
(flaga wersji w `/tmp/sd/yi-hack/.yhcam-ver` — ponowne booty nic nie zmieniają).

## Kroki

1. Karta SD FAT32 (najlepiej sformatowana w kamerce).
2. Pobierz ZIP z [Releases](https://github.com/KlimasTech/yi-hack-cam/releases)
   i wypakuj **zawartość** do katalogu głównego karty. Struktura:
   ```
   |-- yhcam/
   |   |-- yhcam-boot.sh      (samoinstalator)
   |   |-- hook.sh            (patche startowe: go2rtc API, watchdog, mqtt)
   |   |-- uninstall.sh
   |   |-- www/               (panel PL + skrypty CGI)
   |-- README.md, LICENSE
   ```
3. **Jednorazowo** podepnij hook (przez SSH, np. `ssh root@ADRES`):
   ```sh
   grep -q yhcam /tmp/sd/lower_half_init.sh || echo \
     'if [ -x /tmp/sd/yhcam/yhcam-boot.sh ]; then sh /tmp/sd/yhcam/yhcam-boot.sh; fi' \
     >> /tmp/sd/lower_half_init.sh
   reboot
   ```
4. Po reboocie overlay instaluje się sam. Panel: `http://ADRES/`.

## Aktualizacje

- **Z karty:** podmień pliki w `yhcam/` na karcie (np. nowszy ZIP) i zrestartuj
  kamerkę — `yhcam-boot.sh` porówna `www/VERSION` z `.yhcam-ver` i wgrywa nowsze.
- **Z panelu:** zakładka *Aktualizacja* pobiera pliki wprost z GitHuba
  (przeglądarka ma HTTPS, kamerka nie).

## Usuwanie

SSH: `sh /tmp/sd/yhcam/uninstall.sh`, usuń katalog `yhcam/` i wiersz hooka
z `lower_half_init.sh`, restart.
