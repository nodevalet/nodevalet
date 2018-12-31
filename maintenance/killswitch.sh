#!/bin/bash
# This script will stop and disable all installed masternodes

INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
PROJECT=`cat $INFODIR/vpscoin.info`
MNS=`cat $INFODIR/vpsnumber.info`
LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'

# set mnode daemon name from project.env
MNODE_DAEMON=`grep ^MNODE_DAEMON $INSTALLDIR/nodemaster/config/${PROJECT}/${PROJECT}.env`
echo -e "$MNODE_DAEMON" > $INSTALLDIR/temp/MNODE_DAEMON
sed -i "s/MNODE_DAEMON=\${MNODE_DAEMON:-\/usr\/local\/bin\///" $INSTALLDIR/temp/MNODE_DAEMON  2>&1
cat $INSTALLDIR/temp/MNODE_DAEMON | tr -d '[}]' > $INSTALLDIR/temp/MNODE_DAEMON1
MNODE_DAEMON=$(<$INSTALLDIR/temp/MNODE_DAEMON1)
cat $INSTALLDIR/temp/MNODE_DAEMON1 > $INSTALLDIR/temp/MNODE_DAEMON ; rm -f $INSTALLDIR/temp/MNODE_DAEMON1

for ((i=1;i<=$MNS;i++)); 
do

echo -e "\n `date +%m.%d.%Y_%H:%M:%S` : Stopping and disabling masternode ${PROJECT}_n${i}"
MNSTATUS=`/usr/local/bin/${MNODE_DAEMON::-1}-cli -conf=/etc/masternodes/${PROJECT}_n${i}.conf masternode status`
echo -e "$MNSTATUS"

systemctl disable ${PROJECT}_n${i}
systemctl stop ${PROJECT}_n${i}
/usr/local/bin/${MNODE_DAEMON::-1}-cli -conf=/etc/masternodes/${PROJECT}_n${i}.conf stop

done

echo -e "\n"
