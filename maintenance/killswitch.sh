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

echo -e "`date +%m.%d.%Y_%H:%M:%S` : Running killswitch.sh" >> "$LOGFILE"
echo -e " User directed server to shut down and disable all masternodes.\n" >> "$LOGFILE"

for ((i=1;i<=$MNS;i++)); 
do

echo -e "\n `date +%m.%d.%Y_%H:%M:%S` : Stopping and disabling masternode ${PROJECT}_n${i}"

systemctl disable ${PROJECT}_n${i}
systemctl stop ${PROJECT}_n${i}

done

echo -e "\n --> All masternodes have been stopped and disabled"
echo -e " To start them again, use command 'activate_masternodes_${PROJECT}' \n"
