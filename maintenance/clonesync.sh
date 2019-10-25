#!/bin/bash
# Find a synced masternode, stop it, copy its blockchain, then restart them both.

INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
PROJECT=$(cat $INFODIR/vpscoin.info)
MNS=$(cat $INFODIR/vpsnumber.info)
LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
MNODE_DAEMON=$(<$INSTALLDIR/temp/MNODE_DAEMON)
HNAME=$(</var/tmp/nodevalet/info/vpshostname.info)

# extglob was necessary to make rm -- ! possible
shopt -s extglob

# set hostname variable to the name planted by API installation script
if [ -e /var/tmp/nodevalet/info/vpshostname.info ]
then HNAME=$(</var/tmp/nodevalet/info/vpshostname.info)
else HNAME=$(hostname)
fi


WHATEVERNAME=$(<ls /var/tmp/nodevalet/temp | grep "${PROJECT}" | grep last)


# This file will contain if the chain is currently not synced
# $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync  (eg. audax_n2_nosync)

# This file will contain time of when the chain was fully synced
# $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced  (eg. audax_n2_synced)

# This file will contain time of when the chain was last out-of-sync
# $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastoutsync  (eg. audax_n2_lastoutsync)

# If no longer synced, this file will contain last time chain was synced
# $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastnsync  (eg. audax_n2_lastnsync)


# read or assign number of masternodes that are installed
if [ -e $INFODIR/vpsnumber.info ]
then MNS=$(<$INFODIR/vpsnumber.info)
else MNS=1
fi







# read first argument to string
i=$1

# if no argument was given, give instructions and ask for one













if [ -z "$i" ]
then clear
    echo -e "\n This scriptlet will trigger resync the blockchain of a particular node."
    echo -e " It may take awhile. Which masternode would you like to resync? \n"

fi
while :; do
    if [ -z "$i" ] ; then read -p " --> " i ; fi
    [[ $i =~ ^[0-9]+$ ]] || { printf "${lightred}";echo -e "\n --> I only recognize numbers; enter  enter a number between 1 and $MNS...\n"; i=""; continue; }
    if (($i >= 1 && $i <= $MNS)); then break
    else echo -e "\n --> I don't have a masternode $i; enter a number between 1 and $MNS.\n"
        i=""
    fi
done

echo -e "\n"
echo -e "$(date +%m.%d.%Y_%H:%M:%S) : Running resync.sh" | tee -a "$LOGFILE"
echo -e " User has manually asked to resync the chain on ${PROJECT}_n${i}.\n"  | tee -a "$LOGFILE"

touch $INSTALLDIR/temp/updating

echo -e " Disabling ${PROJECT}_n${i} now."
sudo systemctl disable "${PROJECT}"_n${i}
sudo systemctl stop "${PROJECT}"_n${i}
sleep 2
echo -e " Removing blockchain data except wallet.dat and masternode.conf."
cd /var/lib/masternodes/"${PROJECT}"${i}
sudo rm -rf !("wallet.dat"|"masternode.conf")
sleep 2
echo -e " Restarting masternode.\n"
sudo systemctl enable "${PROJECT}"_n${i}
sudo systemctl start "${PROJECT}"_n${i}
echo -e " Resync initiated.\n"

# echo -e " Unsetting -update flag \n"
rm -f $INSTALLDIR/temp/updating
