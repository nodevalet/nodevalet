#!/bin/bash
# This script will give users the 'getinfo' of installed masternodes

INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
PROJECT=`cat $INFODIR/vpscoin.info`
MNS=`cat $INFODIR/vpsnumber.info`
LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'

# extglob was necessary to make rm -- ! possible
shopt -s extglob

# set mnode daemon name from project.env
MNODE_DAEMON=`grep ^MNODE_DAEMON $INSTALLDIR/nodemaster/config/${PROJECT}/${PROJECT}.env`
echo -e "$MNODE_DAEMON" > $INSTALLDIR/temp/MNODE_DAEMON
sed -i "s/MNODE_DAEMON=\${MNODE_DAEMON:-\/usr\/local\/bin\///" $INSTALLDIR/temp/MNODE_DAEMON  2>&1
cat $INSTALLDIR/temp/MNODE_DAEMON | tr -d '[}]' > $INSTALLDIR/temp/MNODE_DAEMON1
MNODE_DAEMON=$(<$INSTALLDIR/temp/MNODE_DAEMON1)
cat $INSTALLDIR/temp/MNODE_DAEMON1 > $INSTALLDIR/temp/MNODE_DAEMON ; rm -f $INSTALLDIR/temp/MNODE_DAEMON1

if [ -e "$INSTALLDIR/temp/updating" ]
	then echo -e "`date +%m.%d.%Y_%H:%M:%S` : Running masternodestatus.sh"
	echo -e "It looks like I'm installing updates; skipping daemon check.\n" 
	exit
fi

for ((i=1;i<=$MNS;i++));
do

echo -e "\n `date +%m.%d.%Y_%H:%M:%S` : Displaying select 'getinfo' from ${PROJECT}_n${i}"
MNSTATUS=`/usr/local/bin/${MNODE_DAEMON::-1}-cli -conf=/etc/masternodes/${PROJECT}_n${i}.conf getinfo`
echo -e "$MNSTATUS" > MNSTATUS
sed '/version\|blocks\|connections/!d' MNSTATUS > MNSTATUS2
cat MNSTATUS2

done
rm -f MNSTATUS
rm -f MNSTATUS2

echo -e "\n"


