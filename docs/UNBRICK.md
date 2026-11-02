# Unbrick — odzyskanie kamery po nieudanym boocie

Model: **y211ga** (offsety i polecenia nizej sa policzone konkretnie dla
tej tabeli partycji flash — dla innego modelu sprawdz `cat /proc/mtd` na
kamerce i przelicz, albo wez wlasciwy folder z
[unbrick/](https://github.com/roleoroleo/yi-hack-Allwinner-v2/tree/master/unbrick)
oryginalnego repo roleoroleo).

```
mtd0: uboot   rozmiar 0x060000  offset 0x000000
mtd1: boot    rozmiar 0x1d0000  offset 0x060000
mtd2: rootfs  rozmiar 0x120000  offset 0x230000
mtd3: home    rozmiar 0x340000  offset 0x350000
mtd4: backup  rozmiar 0x130000  offset 0x690000
mtd5: env     rozmiar 0x020000  offset 0x7c0000
mtd6: mfg     rozmiar 0x010000  offset 0x7e0000
mtd7: conf    rozmiar 0x010000  offset 0x7f0000
```

## ZANIM cokolwiek sie zepsuje: zrob backup

```bash
CAM_HOST=ADRES_KAMERY ./scripts/backup.sh
```

Zrzuca wszystkie partycje (`mtdblock0.bin`...`mtdblock7.bin`) z
kamery do `backups/ADRES_KAMERY/DATA/` na tym komputerze. **Bez tego
backupu "miekki" unbrick (ponizej) nie jest mozliwy** — zostaje tylko
droga przez UART, i to tylko jesli bootloader (mtd0 `uboot`) nie jest
uszkodzony.

Pierwsza linia obrony: **po prostu wyjmij karte SD** — hack (i sd/debug.sh)
zyje tylko na karcie, firmware w flashu nie jest trwale zmieniony. Jesli
kamera nie wstaje nawet bez karty, flash jest realnie uszkodzony i trzeba
isc dalej.

## Droga 1: "miekki" unbrick (bez lutownicy)

Dziala jesli bootloader (U-Boot) wstaje i czyta karte SD — tylko partycje
`rootfs`/`home`/`backup` sa uszkodzone.

1. Na komputerze z Linuksem (WSL albo VM — `mkimage`/`mtd-utils` nie dzialaja
   natywnie na Windows): `sudo apt install mtd-utils u-boot-tools zip`
   i sklonuj `git clone https://github.com/roleoroleo/yi-hack-Allwinner-v2`.
2. Skopiuj **swoj** `mtdblock2.bin`, `mtdblock3.bin`, `mtdblock4.bin` z
   `backups/ADRES_KAMERY/DATA/` (zrobione `scripts/backup.sh` NA DZIALAJACEJ
   kamerze, zanim sie zepsula) do `yi-hack-Allwinner-v2/unbrick/y211ga/`.
   **Te pliki musza pochodzic z TEJ SAMEJ kamery** — bootloader zapisuje
   hash wgranego pliku i odmawia wgrania identycznego ponownie (zob. nizej).
3. `cd yi-hack-Allwinner-v2/unbrick && ./build.sh hacked`
   (albo `./build.sh factory` dla czystego, nie-zhackowanego odzyskania).
4. W `unbrick/y211ga/` powstana `backup_y211ga.gz`, `home_y211ga.gz`,
   `rootfs_y211ga.gz`. Sprawdz czy rozmiar po rozpakowaniu jest zblizony
   do oryginalnego `mtdblockX.bin` — jesli znaczaco mniejszy, `build.sh`
   sie wywalil po drodze (brak `mtd-utils`/`u-boot-tools`).
5. Rozpakuj (`gunzip`) i skopiuj WYNIKOWE pliki (bez `.gz`) do **katalogu
   glownego** karty SD.
6. Wloz karte, wlacz kamerke, zaczekaj ~1-2 min. Bootloader/kernel sam
   wykrywa te pliki na karcie przy starcie i przeszywa odpowiednie
   partycje flash.

**Jesli nie zadziala:** bootloader moze odmowic, bo hash pliku ktory
podajesz jest identyczny z aktualnie wgranym (uszkodzonym) — uzyj
przeciwnej opcji (`factory` zamiast `hacked` albo odwrotnie), `build.sh`
dla wariantu `hacked` dopisuje losowy plik zmieniajacy hash.

## Droga 2: "trudny" unbrick (UART, lutownica)

Gdy droga 1 nie dziala (np. bootloader sam padl) albo gdy nie masz juz
zadnego backupu partycji. Wymaga adaptera USB-TTL podlaczonego do padow
UART (TX/RX/GND) na plycie kamery (otworz obudowe — rozlozenie padow
zalezy od modelu, zdjecia w
[wiki roleoroleo](https://github.com/roleoroleo/yi-hack-Allwinner-v2/wiki/Unbrick-the-cam)).

Ogolna procedura probowania portu/baudu (bez majstrowania batchami
PowerShell przez bash) jest w skillu `yi-hack-cam-firmware`,
`references/serial-uart-debug.md` — uzyj `scripts/serial_probe.ps1`.
Domyslny baud dla U-Boot na tym SoC to **115200**.

1. Na karcie SD w roocie miej `mtdblock4.bin` (partycja `backup`) z
   dzialajacej kamery (wlasnej albo identycznego modelu/hw).
2. Podlacz adapter, otworz PuTTY/serial z logowaniem, wloz kartę, wlacz
   kamerke i **zlap moment startu U-Boot**, wcisnij Enter zeby zatrzymac
   boot na prompcie `=>`.
3. W konsoli U-Boot:
   ```
   => sunxi_card0_probe
   => fatls mmc 0
   => fatload mmc 0 45000000 mtdblock4.bin
   => sf probe
   => sf erase 690000 130000
   => sf write 45000000 690000 130000
   ```
   (`690000` = offset partycji `backup`, `130000` = jej rozmiar — z tabeli
   na górze; dla `rootfs` to `230000`/`120000`, dla `home` — `350000`/`340000`,
   analogicznie jesli trzeba odtworzyc te partycje, nie tylko `backup`).
4. `reset` — kamera powinna wstac z odzyskana partycja `backup` i
   wlasnym bootloaderem/kernelem (ktore same nie byly nadpisywane, wiec
   jesli one zyja, to wystarczy).

**Pelna, ogolna instrukcja (zdjecia padow UART, wszystkie modele):**
https://github.com/roleoroleo/yi-hack-Allwinner-v2/wiki/Unbrick-the-cam

## Po odzyskaniu

Kamera wraca do stanu z backupu (albo "factory", albo "hacked" z
dziala jacym juz samym yi-hack bez yi-hack-cam) — zainstaluj panel
od nowa: [docs/INSTALL-SD.md](INSTALL-SD.md) albo `CAM_HOST=... ./scripts/install.sh`.
