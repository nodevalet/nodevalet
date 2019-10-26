#!/bin/bash
# Find a synced masternode, stop it, copy its blockchain, then restart them both.

INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
PROJECT=$(<$INFODIR/vpscoin.info)
MNS=$(<$INFODIR/vpsnumber.info)
LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
MNODE_DAEMON=$(<$INSTALLDIR/temp/MNODE_DAEMON)
HNAME=$(<$INFODIR/vpshostname.info)

# extglob was necessary to make rm -- ! possible
shopt -s extglob

touch $INSTALLDIR/temp/updating

# read first argument to string
t=$1

# if no argument was given, give instructions and ask for one

if [ -z "$t" ]
then clear
    echo -e "\n This scriptlet will copy a synced blockchain from a fully-synced "
    echo -e " Source Masternode. Which masternode would you like to resync? \n"
fi

while :; do
    if [ -z "$t" ] ; then read -p " --> " t ; fi
    [[ $t =~ ^[0-9]+$ ]] || { printf "${lightred}";echo -e "\n --> I only recognize numbers; enter  enter a number between 1 and $MNS...\n"; t=""; continue; }
    if (($t >= 1 && $t <= $MNS)); then break
    else echo -e "\n --> I don't have a masternode $t; enter a number between 1 and $MNS.\n"
        t=""
    fi
done

# check to see if target masternode is synced or not
sudo bash $INSTALLDIR/maintenance/cronchecksync2.sh "$t"
sleep 2

TARGETSYNC=$(ls /var/tmp/nodevalet/temp | grep "${PROJECT}_n${t}" | grep "synced")
if [[ "${TARGETSYNC}" ]]
then echo -e "* ${PROJECT}_n${t} is already synced *\n"
rm -rf $INSTALLDIR/temp/updating
exit
else echo -e "${PROJECT}_n${t} is not synced and will be clonesynced" | tee -a "$LOGFILE"
fi

# Search for first fully-synced masternode and assign that number to $s
s=0

for ((i=1;i<=$MNS;i++));
do
    echo -e " `date +%m.%d.%Y_%H:%M:%S` : Checking if ${PROJECT}_n${i} is synced."
    sudo bash $INSTALLDIR/maintenance/cronchecksync2.sh "$i"
    sleep 1

    SOURCESYNC=$(ls /var/tmp/nodevalet/temp | grep "${PROJECT}_n${i}" | grep "synced")
    if [[ "${i}" == "${t}" ]]
    then echo -e " ${PROJECT}_n${i} is Target; cannot be Source.\n"

    elif [[ "${SOURCESYNC}" ]]
    then echo -e " ${PROJECT}_n${i} is synced and a valid Source Masternode\n"
    s=$i
    echo -e "Setting Source Masternode to $i"
    break

    else echo -e "${PROJECT}_n${t} is not a valid source; I will try another if it exists."
    fi

done

# Check if a valid Source Masternode was found
if [[ "${s}" == "0" ]]
    then echo -e " Unable to locate valid Source Masternode, stopping.\n"
    rm -rf $INSTALLDIR/temp/updating
    exit
    
else echo -e " Clonesync will now attempt to clone the blockchain from "
    echo -e " ${PROJECT}_n${s} to ${PROJECT}_n${t}. Good luck."



echo -e "This is the part where I would do the things."
echo -e "Exiting because I haven't written the rest of the code yet."
rm -rf $INSTALLDIR/temp/updating
exit




echo -e "\n"
echo -e "$(date +%m.%d.%Y_%H:%M:%S) : Running clonesync.sh" | tee -a "$LOGFILE"
echo -e " Going to clone ${PROJECT}_n${s}'s blockchain onto ${PROJECT}_n${t}'.\n"  | tee -a "$LOGFILE"


echo -e " Disabling Source Masternode ${PROJECT}_n${s} now."
sudo systemctl disable "${PROJECT}"_n${s}
sudo systemctl stop "${PROJECT}"_n${s}

echo -e " Disabling Target Masternode ${PROJECT}_n${t} now."
sudo systemctl disable "${PROJECT}"_n${t}
sudo systemctl stop "${PROJECT}"_n${t}
sleep 2

echo -e " Removing target blockchain data except wallet.dat and masternode.conf."
cd /var/lib/masternodes/"${PROJECT}"${t}
sudo rm -rf !("wallet.dat"|"masternode.conf")
sleep 2

echo -e " Copying source blockchain data from MNx except wallet.dat and masternode.conf."
# cp /var/lib/masternodes/"${PROJECT}"${t}/
# cp !(b*) new_dir/  # this is a sample

cp !("wallet.dat"|"masternode.conf") new_dir/  # this is a sample

sudo rm -rf !("wallet.dat"|"masternode.conf")

echo -e " Restarting Source Masternode ${PROJECT}_n${s}.\n"
sudo systemctl enable "${PROJECT}"_n${s}
sudo systemctl start "${PROJECT}"_n${s}


echo -e " Restarting Target Masternode ${PROJECT}_n${t}.\n"
sudo systemctl enable "${PROJECT}"_n${t}
sudo systemctl start "${PROJECT}"_n${t}


echo -e " Clonesync complete.\n"

# echo -e " Unsetting -update flag \n"
rm -f $INSTALLDIR/temp/updating
exit


fi

# This file will contain if the chain is currently not synced
# $INSTALLDIR/temp/"${PROJECT}"_n${t}_nosync  (eg. audax_n2_nosync)

# This file will contain time of when the chain was fully synced
# $INSTALLDIR/temp/"${PROJECT}"_n${t}_synced  (eg. audax_n2_synced)

# This file will contain time of when the chain was last out-of-sync
# $INSTALLDIR/temp/"${PROJECT}"_n${t}_lastosync  (eg. audax_n2_lastoutsync)

# If no longer synced, this file will contain last time chain was synced
# $INSTALLDIR/temp/"${PROJECT}"_n${t}_lastnsync  (eg. audax_n2_lastnsync)

