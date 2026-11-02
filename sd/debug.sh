#!/bin/sh
# debug.sh — yi-hack's lower_half_init.sh auto-chmods and executes THIS file
# from the SD root on every single boot, if it exists. That's the stock
# hook point yi-hack itself uses for ad-hoc debugging — yi-hack-cam reuses
# it as a self-installer: drop the files on the card, reboot, done. No SSH,
# no editing any other yi-hack script required.
if [ -x /tmp/sd/yhcam/yhcam_install.sh ]; then
    sh /tmp/sd/yhcam/yhcam_install.sh >/tmp/yhcam_install.log 2>&1
fi
