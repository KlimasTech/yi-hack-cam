# Fix: folder `/tmp/sd/Factory` zmienia nazwę na `Factory.done`

## Problem

Na karcie SD kamery (yi-hack) istnieje folder `/tmp/sd/Factory/` z testowymi
skryptami fabrycznymi Xiaomi (`factory_test.sh`, `config.sh`,
`configure_wifi.sh`...). Stockowa binarka **`/home/app/dispatch`** (główny
proces firmware'u Xiaomi) wykrywa ten folder krótko po starcie systemu,
jednorazowo odpala test fabryczny, a potem **sama zmienia nazwę folderu na
`Factory.done`** — żeby nie odpalać testu przy każdym boocie.

Ta logika jest zaszyta w zamkniętej binarce `dispatch` (potwierdzone:
`grep -l factory_test /home/app/dispatch` trafia w binarkę, nie w żaden
edytowalny skrypt shell w `/tmp/sd/yi-hack/script/`). **Nie da się tego
wyłączyć edycją skryptu** — nie istnieje hook/flaga w konfiguracji yi-hack,
która by to zatrzymała.

Zmiana nazwy zachodzi raz na boot, krótko po starcie (obserwowane: kilkanaście–
kilkadziesiąt minut po uruchomieniu kamery; `dispatch` nie loguje tej operacji,
więc dokładnego timingu nie da się potwierdzić z logów — `DEBUG_LOG=no`
w stocku, a znaczniki czasu na FAT dla tego wpisu są fikcyjne `Jan 1 1980`).

## Rozwiązanie: watchdog przywracający nazwę

Nie naprawiamy `dispatch` (niemożliwe bez dekompilacji/patchowania binarki) —
**obchodzimy efekt**: watchdog yi-hacka (`wd.sh`), który już chodzi w tle
w pętli co ~10 s (`INTERVAL=10`) i sprawdza stan RTSP/WiFi/rmm/mqtt, dostaje
dodatkową funkcję, która wykrywa `Factory.done` i odrazu zmienia nazwę
z powrotem na `Factory`.

### Krok 1 — ściągnij `wd.sh` z kamery

```
pscp.exe -hostkey SHA256:<fingerprint> -pw "" root@<CAMERA_IP>:/tmp/sd/yi-hack/script/wd.sh wd.sh
```

(hasło roota na yi-hack jest puste; fingerprint host-key wypisze plink przy
pierwszym połączeniu — zobacz `docs/TROUBLESHOOTING.md` w tym repo).

### Krok 2 — dodaj funkcję `check_factory_folder`

Wstaw tę funkcję w `wd.sh` obok innych `check_*` (np. przed blokiem
`if [[ $(get_config RTSP) == "no" ]] ; then exit; fi` na końcu pliku):

```sh
check_factory_folder()
{
    # Stockowy dispatch po jednorazowym teście fabrycznym zmienia nazwę
    # /tmp/sd/Factory na /tmp/sd/Factory.done (zaszyte w binarce, nie w skrypcie).
    # Przywracamy nazwę z powrotem, żeby folder zawsze był widoczny jako "Factory".
    if [ -d /tmp/sd/Factory.done ] && [ ! -e /tmp/sd/Factory ]; then
        mv /tmp/sd/Factory.done /tmp/sd/Factory
        echo "$(date +'%Y-%m-%d %H:%M:%S') - Factory.done -> Factory (przywrócono nazwę)" >> $LOG_FILE
    fi
}
```

### Krok 3 — wywołaj ją w głównej pętli `while true; do ... done`

Dopisz wywołanie obok istniejących `check_rtsp*`/`check_mqtt`/`check_wifi`:

```sh
    check_rmm
    check_mqtt
    check_wifi
    check_factory_folder
```

### Krok 4 — wgraj i zrestartuj watchdoga

```
pscp.exe -hostkey SHA256:<fingerprint> -pw "" wd.sh root@<CAMERA_IP>:/tmp/sd/yi-hack/script/wd.sh
```

**Pułapka:** `killall wd.sh` zwykle NIE działa — proces widać w `ps` jako
`/bin/sh` (nazwa skryptu nie jest nazwą procesu na niektórych modelach).
Zabij po PID i odpal ręcznie w tle:

```
plink.exe -ssh -pw "" -batch -hostkey SHA256:<fingerprint> root@<CAMERA_IP> \
  "ps ww | grep '[w]d.sh'"                     # znajdź PID
plink.exe -ssh -pw "" -batch -hostkey SHA256:<fingerprint> root@<CAMERA_IP> \
  "kill -9 <PID>; sleep 1; (/tmp/sd/yi-hack/script/wd.sh >/dev/null 2>&1 &)"
```

Zweryfikuj, że działa tylko JEDNA instancja (`ps ww | grep '[w]d.sh'` — jeden
wiersz) i że folder jest z powrotem `Factory`:

```
plink.exe ... "ls -la /tmp/sd/ | grep -i factory"
```

## Ograniczenia tego obejścia

- To jest polling, nie prawdziwa blokada — między zmianą nazwy przez `dispatch`
  a najbliższym przebiegiem pętli watchdoga (do ~10 s) folder chwilowo jest
  `Factory.done`. Jeśli coś zewnętrznego sprawdza nazwę folderu akurat w tym
  oknie, złapie starą nazwę — w praktyce bardzo mało prawdopodobne.
- Patch żyje tylko na karcie SD (`/tmp/sd/yi-hack/script/wd.sh`) — przy
  reflashu/wymianie karty trzeba go nałożyć ponownie. Jeśli kamera korzysta
  z instalatora tego repo (`scripts/install.sh` / pakiet SD w `sd/yhcam/`),
  rozważ dopisanie tej samej funkcji do źródła instalatora, żeby nie zginęła
  przy reinstalacji.
