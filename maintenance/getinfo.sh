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
	echo -e " It looks like I'm installing updates; skipping daemon check.\n" 
	exit
fi

# read first argument to string
input=$1

if [ -z $input ] ; then :
else
while :; do
	 
	if [ -z $input ] ; then read -p "  --> " input ; fi
	[[ $input =~ ^[0-9]+$ ]] || { printf "${lightred}";echo -e "\n I'm sorry; but I only recognize numbers of masternodes on this VPS.\n Which masternode would you like to getinfo on? \n"; input=""; continue; }
	if (($input >= 1 && $input <= $MNS)); then break
	else echo -e "\n --> Can't find masternode $input, try again. \n"
	input=""
	fi
done

# Display 'getinfo' for only the masternode named
echo -e "\n `date +%m.%d.%Y_%H:%M:%S` : Displaying select 'getinfo' from ${PROJECT}_n${input}"
GETINFO=`/usr/local/bin/${MNODE_DAEMON::-1}-cli -conf=/etc/masternodes/${PROJECT}_n${input}.conf getinfo`
echo -e "$GETINFO" > GETINFO
sed '/version\|blocks\|connections/!d' GETINFO > GETINFO2
cat GETINFO2
rm -f GETINFO
rm -f GETINFO2
echo -e "\n"
exit

fi

# Display 'getinfo' for all masternodes
for ((i=1;i<=$MNS;i++));
do
	echo -e "\n `date +%m.%d.%Y_%H:%M:%S` : Displaying select 'getinfo' from ${PROJECT}_n${i}"
	GETINFO=`/usr/local/bin/${MNODE_DAEMON::-1}-cli -conf=/etc/masternodes/${PROJECT}_n${i}.conf getinfo`
	echo -e "$GETINFO" > GETINFO
	sed '/version\|blocks\|connections/!d' GETINFO > GETINFO2
	cat GETINFO2
done
rm -f GETINFO
rm -f GETINFO2
echo -e "\n"
exit

