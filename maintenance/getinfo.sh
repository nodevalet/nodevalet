#!/bin/bash
# This script will give users the 'getinfo' of installed masternodes

INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
PROJECT=$(<$INFODIR/vpscoin.info)
MNS=$(<$INFODIR/vpsnumber.info)
LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
MNODE_DAEMON=$(<$INFODIR/vpsmnode_daemon.info)
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

if [ -e "$INSTALLDIR/temp/updating" ]
then echo -e " ${nocolor}$(date +%m.%d.%Y_%H:%M:%S) : Running getinfo.sh"
    echo -e " It looks like I'm busy with something else; sorry.\n"
    exit
fi

# read first argument to string
input=$1

if [ -z "$input" ] ; then :
else
    while :; do

        if [ -z "$input" ] ; then read -p "  --> " input ; fi
        [[ $input =~ ^[0-9]+$ ]] || { printf "${lightred}";echo -e "\n${lightred} I'm sorry; but I only recognize numbers of masternodes on this VPS.\n Which masternode would you like to getinfo on? ${nocolor}\n"; input=""; continue; }
        if (($input >= 1 && $input <= $MNS)); then break
        else echo -e "\n${lightred} --> Can't find masternode $input, try again. ${nocolor}\n"
            input=""
        fi
    done

    # Display 'getinfo' for only the masternode named
    echo -e "\n $(date +%m.%d.%Y_%H:%M:%S) : Displaying select 'getinfo' from Masternode${lightcyan} ${PROJECT}_n${input}${nocolor}"
    sudo bash $INSTALLDIR/maintenance/cronchecksync2.sh "$input" > /dev/null 2>&1
    GETINFO=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n${input}.conf getinfo)
    echo -e "$GETINFO" > GETINFO
    sed '/version\|blocks\|connections/!d' GETINFO > GETINFO2
    cat GETINFO2
    rm -f GETINFO
    rm -f GETINFO2

    # check if file exists with name that contains both "audax_n1" and "synced"
    TARGETSYNC=$(ls /var/tmp/nodevalet/temp | grep "${PROJECT}_n${input}" | grep "synced")
    if [[ "${TARGETSYNC}" ]]
    then echo -e "${lightgreen}                     Masternode ${PROJECT}_n${input} is synced.${nocolor}\n"
    else echo -e "${lightred}                     Masternode ${PROJECT}_n${input} is not synced.${nocolor}\n"
    fi
    exit

fi

# Display 'getinfo' for all masternodes
for ((i=1;i<=$MNS;i++));
do
    echo -e "\n $(date +%m.%d.%Y_%H:%M:%S) : Displaying select 'getinfo' from Masternode${lightcyan} ${PROJECT}_n${i}${nocolor}"
    sudo bash $INSTALLDIR/maintenance/cronchecksync2.sh "$i" > /dev/null 2>&1
    GETINFO=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n${i}.conf getinfo)
    echo -e "$GETINFO" > GETINFO
    sed '/version\|blocks\|connections/!d' GETINFO > GETINFO2
    cat GETINFO2
   
    # check if file exists with name that contains both "audax_n1" and "synced"
    TARGETSYNC=$(ls /var/tmp/nodevalet/temp | grep "${PROJECT}_n${i}" | grep "synced")
    if [[ "${TARGETSYNC}" ]]
    then echo -e "${lightgreen}                     Masternode ${PROJECT}_n${i} is synced.${nocolor}\n"
    else echo -e "${lightred}                     Masternode ${PROJECT}_n${i} is not synced.${nocolor}\n"
    fi

done
rm -f GETINFO
rm -f GETINFO2

exit

