#!/bin/bash
# Wipe stuck masternode chains and force a full resync  

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


# read first argument to string $NEWMAX
i=$1

# if NEWMAX(value only)=0 give instructions and echo them

if [ -z $i ]
then clear
        echo -e "\n It seems like you're trying to resync a particular node"
        echo -e "  This may take awhile. Which masternode would you like to resync? \n"

fi

while :; do
if [ -z $i ] ; then read -p "  --> " i ; fi
[[ $i =~ ^[0-9]+$ ]] || {echo -e " --> I only recognize numbers."; continue; }
if (($i >= 1 && $i <= $MNS)); then break
else echo -e "\n --> Can't find masternode $i, try again. \n"
i=""
fi
done
echo -e "\n"
echo -e "`date +%m.%d.%Y_%H:%M:%S` : Running resync.sh" | tee -a "$LOGFILE"
echo -e "User has manually asked to resync the chain on ${PROJECT}_n${i}.\n"  | tee -a "$LOGFILE"
  
touch $INSTALLDIR/temp/updating

		echo -e " Disabling ${PROJECT}_n${i} now."
    sudo systemctl disable ${PROJECT}_n${i}
		sudo systemctl stop ${PROJECT}_n${i}
		sleep 2
    echo -e " Removing blockchain data except wallet.dat and masternode.conf now."
		cd /var/lib/masternodes/${PROJECT}${i}
		sudo rm -rf !("wallet.dat"|"masternode.conf")
		sleep 2
		echo -e " Restarting masternode."
    sudo systemctl enable ${PROJECT}_n${i}
		sudo systemctl start ${PROJECT}_n${i}		
		echo -e " Resync initiated.\n"

# echo -e " Unsetting -update flag \n"
rm -f $INSTALLDIR/temp/updating
