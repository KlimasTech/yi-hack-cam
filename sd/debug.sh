#!/bin/sh
# debug.sh — yi-hack's lower_half_init.sh auto-chmods and executes THIS file
# from the SD root on every single boot, if it exists. That's the stock
# hook point yi-hack itself uses for ad-hoc debugging — yi-hack-cam reuses
# it as a self-installer: drop the files on the card, reboot, done. No SSH,
# no editing any other yi-hack script required.
if [ -f /tmp/sd/yhcam/yhcam_install.sh ]; then
    # FAT32 nie garantuje bitu +x domyslnie (patrz lower_half_init.sh, ktore
    # robi explicit chmod 777 na kazdym skrypcie PRZED jego odpaleniem) -
    # dlatego chmodujemy tutaj explicit, a nie sprawdzamy -x (ktory moze byc
    # falszywy na FAT32 nawet gdy plik jest czytelny i "sh plik" by zadzialalo).
    chmod 755 /tmp/sd/yhcam/yhcam_install.sh 2>/dev/null
    sh /tmp/sd/yhcam/yhcam_install.sh >/tmp/yhcam_install.log 2>&1
fi
