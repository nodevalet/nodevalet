#!/bin/bash
# This script will give users the masternode status of installed masternodes

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
	echo -e "It looks like I'm installing updates; skipping masternodestatus.\n" 
	exit
fi

# read first argument to string
input=$1

if [ -z $input ] ; then :
else
while :; do
	 
	if [ -z $input ] ; then read -p "  --> " input ; fi
	[[ $input =~ ^[0-9]+$ ]] || { printf "${lightred}";echo -e "\n I'm sorry; but I only recognize numbers of masternodes on this VPS.\n Which masternode would you like to see masternode status for? \n"; input=""; continue; }
	if (($input >= 1 && $input <= $MNS)); then break
	else echo -e "\n --> Can't find masternode $input, try again. \n"
	input=""
	fi
done

# Display 'masternode status' for only the masternode named
echo -e "\n `date +%m.%d.%Y_%H:%M:%S` : Checking masternode status of ${PROJECT}_n${input}"
MNSTATUS=`/usr/local/bin/${MNODE_DAEMON::-1}-cli -conf=/etc/masternodes/${PROJECT}_n${input}.conf masternode status`
echo -e "$MNSTATUS"
exit

fi

# Display 'masternode status' for all masternodes
for ((i=1;i<=$MNS;i++)); 
do

echo -e "\n `date +%m.%d.%Y_%H:%M:%S` : Checking masternode status of ${PROJECT}_n${i}"
MNSTATUS=`/usr/local/bin/${MNODE_DAEMON::-1}-cli -conf=/etc/masternodes/${PROJECT}_n${i}.conf masternode status`
echo -e "$MNSTATUS"

done

echo -e "\n"
