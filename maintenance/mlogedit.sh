#!/bin/bash

LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
MNS=$(<$INFODIR/vpsnumber.info)
PROJECT=$(<$INFODIR/vpscoin.info)
PROJECTl=${PROJECT,,}
PROJECTt=${PROJECTl~}
MNODE_DAEMON=$(<$INFODIR/vpsmnode_daemon.info)
HNAME=$(<$INFODIR/vpshostname.info)

nano -c $LOGFILE

echo -e "\n"
echo -e " $(date +%m.%d.%Y_%H:%M:%S) : mlogedit.sh was run to modify the Maintenance Log.\n" | tee -a "$LOGFILE"

echo -e " Your edits to the Maintenance Log have been logged. \n"
