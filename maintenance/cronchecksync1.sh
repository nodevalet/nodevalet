#!/bin/bash

# Set Variables
LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
PROJECT=$(cat $INFODIR/vpscoin.info)
MNODE_DAEMON=$(<$INSTALLDIR/temp/MNODE_DAEMON)
PROJECTl=${PROJECT,,}
PROJECTt=${PROJECTl~}

# read or assign number of masternodes that are installed
if [ -e $INFODIR/vpsnumber.info ]
then MNS=$(<$INFODIR/vpsnumber.info)
else MNS=1
fi

for ((i=1;i<=$MNS;i++));
do
    echo -e "\n `date +%m.%d.%Y_%H:%M:%S` : Checking if ${PROJECT}_n${i} is synced." >> "$LOGFILE"
    sudo bash $INSTALLDIR/maintenance/cronchecksync2.sh "$i"
    sleep 5
done

exit


