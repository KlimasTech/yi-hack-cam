# Przygotowanie karty SD (instalacja w stylu yi-hack)

## Jak to dziala

yi-hack przy **kazdym** boocie, w `lower_half_init.sh`, sprawdza czy na
karcie SD istnieje plik `/tmp/sd/debug.sh` i jesli tak — chmoduje go 777 i
odpala. To jest wbudowany hook producenta/yi-hack (sluzy do ad-hoc
debugowania), zupelnie niezalezny od `system.sh`/`wd.sh`. yi-hack-cam
podczepia sie wlasnie tam.

**Nie trzeba edytowac zadnego pliku yi-hack recznie przez SSH** — samo
wgranie plikow na karte i restart wystarczy, dokladnie jak przy instalacji
oryginalnego yi-hack z pakietu producenta.

## Kroki

1. Karta SD FAT32 (najlepiej sformatowana w kamerce), z dzialajacym juz
   yi-hack (`/tmp/sd/yi-hack` istnieje).
2. Pobierz ZIP z [Releases](https://github.com/KlimasTech/yi-hack-cam/releases)
   i wypakuj **zawartosc** do katalogu glownego karty. Struktura:
   ```
   (root karty SD)
   |-- debug.sh              <- hook wykrywany przez yi-hack co boot
   |-- yhcam/
   |   |-- yhcam_install.sh  <- wywolywany przez debug.sh (samoinstalator)
   |   |-- hook.sh           <- patche startowe (go2rtc API, watchdog, mqtt)
   |   |-- uninstall.sh
   |   |-- bin/ lib/         <- hostapd + libs dla trybu AP
   |   |-- www/              <- panel PL + skrypty CGI
   |-- README.md, LICENSE
   ```
3. Wloz karte do kamerki i zrestartuj. `debug.sh` odpala sie na TYM samym
   boocie, przed startem uslug (`system.sh`) — wiec panel, go2rtc i blokada
   chmury dzialaja juz od pierwszego boota, bez dodatkowego restartu.
4. Panel: `http://ADRES_KAMERKI/`.

## Jak to sie rozni od instalacji przez SSH

`scripts/install.sh` robi to samo przez siec: wgrywa `sd/debug.sh` +
`sd/yhcam/` na karte przez `scp`/`pscp`, odpala `yhcam_install.sh` zdalnie,
i dodatkowo restartuje usługi (bo kamera juz dziala i trzeba dobic stare
procesy `cloud`/`telnetd`/`wd.sh`) — przy swiezym boocie z karty to niepotrzebne.
Logika instalacji (`yhcam_install.sh`) jest jedna, uzywana w obu sciezkach.

## Aktualizacje

- **Z karty:** podmien pliki w `yhcam/` na karcie (np. nowszy ZIP) i
  zrestartuj kamerke — `debug.sh` odpala `yhcam_install.sh` ponownie przy
  kazdym boocie, instalator jest idempotentny i po prostu nadpisuje pliki.
- **Przez siec:** `CAM_HOST=ADRES ./scripts/install.sh` ponownie.
- **Z panelu:** zakladka *Aktualizacja* pobiera pliki wprost z GitHuba
  (przegladarka ma HTTPS, kamerka nie).

## Usuwanie

- **Z karty/SSH:** `sh /tmp/sd/yhcam/uninstall.sh` — zdejmuje hook z
  `system.sh`, usuwa pliki panelu i binarki AP, przywraca `service.sh`/
  `wd.sh` z backupu, **usuwa `/tmp/sd/debug.sh`** (zeby nic sie juz
  samo nie doinstalowalo po restarcie), restart.
- **Przez siec:** `CAM_HOST=ADRES ./scripts/uninstall.sh` (wola ten sam
  skrypt przez SSH).
