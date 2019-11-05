#!/bin/bash

# Set Variables

LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
MNS=$(<$INFODIR/vpsnumber.info)
PROJECT=$(<$INFODIR/vpscoin.info)
PROJECTl=${PROJECT,,}
PROJECTt=${PROJECTl~}
MNODE_DAEMON=$(<$INFODIR/vpsmnode_daemon.info)
HNAME=$(<$INFODIR/vpshostname.info)

clear

# Proceed to check if each masternode is synced or not
for ((i=1;i<=$MNS;i++));
do
    echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Checking if ${PROJECT}_n${i} is synced."
    # echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Checking if ${PROJECT}_n${i} is synced." | tee -a "$LOGFILE"
    sudo bash $INSTALLDIR/maintenance/cronchecksync2.sh "$i"
    sleep .25
done

# echo -e " \n" | tee -a "$LOGFILE"

exit
