#!/bin/bash
# Find a synced masternode, stop it, copy its blockchain, then restart them both.

LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
MNS=$(<$INFODIR/vpsnumber.info)
PROJECT=$(<$INFODIR/vpscoin.info)
PROJECTl=${PROJECT,,}
PROJECTt=${PROJECTl~}
MNODE_DAEMON=$(<$INFODIR/vpsmnode_daemon.info)
HNAME=$(<$INFODIR/vpshostname.info)

clear

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

touch $INSTALLDIR/temp/updating

# read first argument to string
t=$1

# if no argument was given, give instructions and ask for one

if [ -z "$t" ]
then clear
    echo -e "\n${lightcyan} This scriptlet will copy a synced blockchain from a fully-synced "
    echo -e " Source Masternode. Which masternode would you like to resync? ${nocolor}\n"
fi

while :; do
    if [ -z "$t" ] ; then read -p " --> " t ; fi
    [[ $t =~ ^[0-9]+$ ]] || { printf "${lightred}"; echo -e "\n --> I only recognize numbers; enter a number between 1 and $MNS...\n"; t=""; printf "${nocolor}"; continue; }
    if (($t >= 1 && $t <= $MNS)); then break
    else echo -e "\n${lightred} --> I don't have a masternode $t; enter a number between 1 and $MNS.${nocolor}\n"
        t=""
    fi
done

# check to see if target masternode is synced or not
sudo bash $INSTALLDIR/maintenance/cronchecksync2.sh "$t" > /dev/null 2>&1
sleep 1

# check if file exists with name that contains both "audax_n1" and "synced"
TARGETSYNC=$(ls /var/tmp/nodevalet/temp | grep "${PROJECT}_n${t}" | grep "synced")
if [[ "${TARGETSYNC}" ]]
then echo -e "\n${lightgreen}* Masternode ${PROJECT}_n${t} is already synced *${nocolor}\n"
    rm -rf $INSTALLDIR/temp/updating
    exit
else echo -e "\n${lightcyan} Masternode ${PROJECT}_n${t} is not synced and will be clonesynced${nocolor}\n"
fi

# Search for first fully-synced masternode and assign that number to $s
s=0

for ((i=1;i<=$MNS;i++));
do
    echo -e " $(date +%m.%d.%Y_%H:%M:%S) :${white} Checking if ${PROJECT}_n${i} is synced.${nocolor}"
    sudo bash $INSTALLDIR/maintenance/cronchecksync2.sh "$i" > /dev/null 2>&1
    sleep 1

    SOURCESYNC=$(ls /var/tmp/nodevalet/temp | grep "${PROJECT}_n${i}" | grep "synced")
    if [[ "${i}" == "${t}" ]]
    then echo -e "${lightred} Masternode ${PROJECT}_n${i} is Target; cannot be Source.${nocolor}\n"

elif [[ "${SOURCESYNC}" ]]
    then echo -e "${lightgreen} Masternode ${PROJECT}_n${i} is synced and a valid Source Masternode.${nocolor}"
        s=$i
        echo -e "${lightgreen} Setting Source Masternode to $i${nocolor}\n"
        break

    else echo -e "${lightred} Masternode ${PROJECT}_n${t} is not synced so it is not a valid source.${nocolor}\n"
    fi
done

# Check if a valid Source Masternode was found
if [[ "${s}" == "0" ]]
then echo -e " Unable to locate valid Source Masternode, stopping.\n" | tee -a "$LOGFILE"
    rm -rf $INSTALLDIR/temp/updating
    exit

else echo -e "${lightcyan} Clonesync will now attempt to clone the blockchain "
    echo -e " from ${PROJECT}_n${s} to ${PROJECT}_n${t}.  Best of luck!${nocolor}"

    echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Running clonesync.sh" >> "$LOGFILE"
    echo -e " Going to clone ${PROJECT}_n${s}'s blockchain onto ${PROJECT}_n${t}." >> "$LOGFILE"

    echo -e "\n${lightred} Disabling Source Masternode ${PROJECT}_n${s} now.${nocolor}"
    sudo systemctl disable "${PROJECT}"_n${s} > /dev/null 2>&1
    sudo systemctl stop "${PROJECT}"_n${s}

    echo -e "${lightred} Disabling Target Masternode ${PROJECT}_n${t} now.${nocolor}"
    sudo systemctl disable "${PROJECT}"_n${t} > /dev/null 2>&1
    sudo systemctl stop "${PROJECT}"_n${t}
    sleep 2

    echo -e "${lightred} Removing relevant target blockchain data.${nocolor}\n"
    cd /var/lib/masternodes/"${PROJECT}"${t}
    sudo rm -rf !("wallet.dat"|"masternode.conf")
    sleep 2

    # copy blocks/chainstate/sporks with permissions (cp -rp) or it will fail
    cd /var/lib/masternodes/"${PROJECT}"${s}
    echo -e "${lightcyan} Copying source blockchain data (blocks/chainstate/blocks)${nocolor}"
    cp -rp /var/lib/masternodes/"${PROJECT}${s}"/blocks /var/lib/masternodes/"${PROJECT}${t}"/blocks
    echo -e "${lightcyan} Copying source blockchain data (blocks/chainstate/chainstate)${nocolor}"
    cp -rp /var/lib/masternodes/"${PROJECT}${s}"/chainstate /var/lib/masternodes/"${PROJECT}${t}"/chainstate
    echo -e "${lightcyan} Copying source blockchain data (blocks/chainstate/sporks)${nocolor}\n"
    cp -rp /var/lib/masternodes/"${PROJECT}${s}"/sporks /var/lib/masternodes/"${PROJECT}${t}"/sporks

    # copy weird bootstraps like Phore
    if [ -s /var/lib/masternodes/"${PROJECT}${s}"/bootstrap.dat ]
    then cp -p /var/lib/masternodes/"${PROJECT}${s}"/bootstrap.dat /var/lib/masternodes/"${PROJECT}${t}"/
    else :
    fi

    echo -e "${white} Restarting Source Masternode ${PROJECT}_n${s}.${nocolor}"
    sudo systemctl enable "${PROJECT}"_n${s} > /dev/null 2>&1
    sudo systemctl start "${PROJECT}"_n${s}

    echo -e "${white} Restarting Target Masternode ${PROJECT}_n${t}.${nocolor}"
    sudo systemctl enable "${PROJECT}"_n${t} > /dev/null 2>&1
    sudo systemctl start "${PROJECT}"_n${t}

    echo -e "${lightgreen} Clonesync complete; Masternodes have been restarted.${nocolor}\n" | tee -a "$LOGFILE"

    # echo -e " Unsetting -update flag"
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
