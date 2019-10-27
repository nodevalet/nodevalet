#!/bin/bash
# This script will give users the masternode status of installed masternodes

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

if [ -e "$INSTALLDIR/temp/updating" ]
then echo -e "$(date +%m.%d.%Y_%H:%M:%S) : Running masternodestatus.sh"
    echo -e "It looks like I'm installing updates; skipping masternodestatus.\n"
    exit
fi

# read first argument to string
input=$1

if [ -z "$input" ] ; then :
else
    while :; do

        if [ -z "$input" ] ; then read -p "  --> " input ; fi
        [[ $input =~ ^[0-9]+$ ]] || { printf "${lightred}";echo -e "\n I'm sorry; but I only recognize numbers of masternodes on this VPS.\n Which masternode would you like to see masternode status for? \n"; input=""; continue; }
        if (($input >= 1 && $input <= $MNS)); then break
        else echo -e "\n --> Can't find masternode $input, try again. \n"
            input=""
        fi
    done

    # Display 'masternode status' for only the masternode named
    echo -e "\n $(date +%m.%d.%Y_%H:%M:%S) : Checking masternode status of ${PROJECT}_n${input}"
    if [ "${PROJECT,,}" = "smart" ] ; then MNSTATUS=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n${input}.conf smartnode status)
else MNSTATUS=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n${input}.conf masternode status) ; fi
    echo -e "$MNSTATUS"
    exit

fi

# Display 'masternode status' for all masternodes
for ((i=1;i<=$MNS;i++));
do

    echo -e "\n $(date +%m.%d.%Y_%H:%M:%S) : Checking masternode status of ${PROJECT}_n${i}"
    if [ "${PROJECT,,}" = "smart" ] ; then MNSTATUS=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n${i}.conf smartnode status)
else MNSTATUS=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n${i}.conf masternode status) ; fi
    echo -e "$MNSTATUS"

done

echo -e "\n"
