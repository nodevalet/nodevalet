#!/bin/bash
# Wipe stuck masternode chains and force a full resync

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

# extglob was necessary to make rm -- ! possible
shopt -s extglob

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
echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Running resync.sh" | tee -a "$LOGFILE"
echo -e " User has manually asked to resync the chain on ${PROJECT}_n${i}.\n"  | tee -a "$LOGFILE"

touch $INSTALLDIR/temp/updating

# remove synced flag, set not synced flag
if [ -e $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced ]
then cp $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastnsync
    rm $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced --force
fi
touch $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync

echo -e "${lightred} Disabling ${PROJECT}_n${i} now.${nocolor}"
sudo systemctl disable "${PROJECT}"_n${i} > /dev/null 2>&1
sudo systemctl stop "${PROJECT}"_n${i}
sleep 2

echo -e "${white} Removing blockchain data.${nocolor}"
cd /var/lib/masternodes/"${PROJECT}"${i}
rm $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced --force
sudo rm -rf !("wallet.dat"|"masternode.conf")
sleep 2

echo -e "${lightgreen} Restarting masternode.${nocolor}"
sudo systemctl enable "${PROJECT}"_n${i} > /dev/null 2>&1
sudo systemctl start "${PROJECT}"_n${i}
echo -e "${lightcyan} Resync of ${PROJECT}_n${i} initiated.${nocolor}\n"

# echo -e " Unsetting -update flag \n"
rm -f $INSTALLDIR/temp/updating
