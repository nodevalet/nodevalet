#!/bin/bash
# This script will stop and disable all installed masternodes

INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
PROJECT=$(<$INFODIR/vpscoin.info)
MNS=$(<$INFODIR/vpsnumber.info)
LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
MNODE_DAEMON=$(<$INFODIR/vpsmnode_daemon.info)
HNAME=$(<$INFODIR/vpshostname.info)

echo -e "$(date +%m.%d.%Y_%H:%M:%S) : Running killswitch.sh" >> "$LOGFILE"
echo -e " User directed server to shut down and disable all masternodes.\n" >> "$LOGFILE"

touch $INSTALLDIR/temp/updating

for ((i=1;i<=$MNS;i++));
do
    echo -e "\n $(date +%m.%d.%Y_%H:%M:%S) : Stopping and disabling masternode ${PROJECT}_n${i}"
    systemctl disable "${PROJECT}"_n${i}
    systemctl stop "${PROJECT}"_n${i}
done

echo -e "\n --> All masternodes have been stopped and disabled"
echo -e " To start them again, use command 'activate_masternodes_${PROJECT}' \n"

rm -f $INSTALLDIR/temp/updating
