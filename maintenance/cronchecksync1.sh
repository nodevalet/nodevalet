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

if [ -e "$INSTALLDIR/temp/shuttingdown" ]
then echo -e " Skipping cronchecksync1.sh because the server is shutting down.\n"
    exit
fi

if [ -e "$INSTALLDIR/temp/activating" ]
then echo -e " Skipping cronchecksync1.sh because the server is activating masternodes.\n"
    exit
fi

# Proceed to check if each masternode is synced or not
for ((i=1;i<=$MNS;i++));
do
    echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Checking if ${PROJECT}_n${i} is synced."
    sudo bash $INSTALLDIR/maintenance/cronchecksync2.sh "$i"
    sleep .25
done

exit
