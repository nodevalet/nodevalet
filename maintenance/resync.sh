#!/bin/bash
# Wipe stuck masternode chains and force a full resync

INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
PROJECT=$(<$INFODIR/vpscoin.info)
MNS=$(<$INFODIR/vpsnumber.info)
LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
MNODE_DAEMON=$(<$INSTALLDIR/temp/MNODE_DAEMON)
HNAME=$(<$INFODIR/vpshostname.info)

### define colors ###
lightred=$'\033[1;31m'  # light red
red=$'\033[0;31m'  # red
lightgreen=$'\033[1;32m'  # light green
green=$'\033[0;32m'  # green
lightblue=$'\033[1;34m'  # light blue
blue=$'\033[0;34m'  # blue
lightpurple=$'\033[1;35m'  # light purple
purple=$'\033[0;35m'  # purple
lightcyan=$'\033[1;36m'  # light cyan
cyan=$'\033[0;36m'  # cyan
lightgray=$'\033[0;37m'  # light gray
white=$'\033[1;37m'  # white
brown=$'\033[0;33m'  # brown
yellow=$'\033[1;33m'  # yellow
darkgray=$'\033[1;30m'  # dark gray
black=$'\033[0;30m'  # black
nocolor=$'\e[0m' # no color

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

echo -e " Disabling ${PROJECT}_n${i} now."
sudo systemctl disable "${PROJECT}"_n${i}
sudo systemctl stop "${PROJECT}"_n${i}
sleep 2

echo -e " Removing blockchain data except wallet.dat and masternode.conf."
cd /var/lib/masternodes/"${PROJECT}"${i}
rm $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced --force
sudo rm -rf !("wallet.dat"|"masternode.conf")
sleep 2

echo -e " Restarting masternode.\n"
sudo systemctl enable "${PROJECT}"_n${i}
sudo systemctl start "${PROJECT}"_n${i}
echo -e " Resync initiated.\n"

# echo -e " Unsetting -update flag \n"
rm -f $INSTALLDIR/temp/updating
