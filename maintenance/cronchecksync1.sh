#!/bin/bash

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

clear

if [ -e "$INSTALLDIR/temp/shuttingdown" ]
then echo -e " Skipping cronchecksync1.sh because the server is shutting down.\n"
    exit
fi

if [ -e "$INSTALLDIR/temp/updating" ]
then echo -e " Skipping cronchecksync1.sh because the server is updating.\n"
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
