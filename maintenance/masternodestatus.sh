#!/bin/bash
# This script will give users the masternode status of installed masternodes

# exit with error if not run as root/sudo
if [ "$(id -u)" != "0" ]
then echo -e "\n Please re-run as root or sudo.\n"
    exit 1
fi

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

# extglob was necessary to make rm -- ! possible
shopt -s extglob

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
    if [ "${PROJECT,,}" = "smart" ]
    then MNSTATUS=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n${input}.conf smartnode status)
    elif [ "${PROJECT,,}" = "pivx" ] || [ "${PROJECT,,}" = "squorum" ] || [ "${PROJECT,,}" = "wagerr" ] || [ "${PROJECT,,}" = "alqo" ]
    then MNSTATUS=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n${input}.conf masternodedebug)
    else MNSTATUS=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n${input}.conf masternode status)
    fi
    echo -e "$MNSTATUS"
    exit

fi

# Display 'masternode status' for all masternodes
for ((i=1;i<=$MNS;i++));
do

    echo -e "\n $(date +%m.%d.%Y_%H:%M:%S) : Checking masternode status of ${PROJECT}_n${i}"
    if [ "${PROJECT,,}" = "smart" ]
    then MNSTATUS=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n${i}.conf smartnode status)
    elif [ "${PROJECT,,}" = "pivx" ] || [ "${PROJECT,,}" = "squorum" ] || [ "${PROJECT,,}" = "wagerr" ] || [ "${PROJECT,,}" = "alqo" ]
    then MNSTATUS=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n${i}.conf masternodedebug)
    else MNSTATUS=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n${i}.conf masternode status)
    fi
    echo -e "$MNSTATUS"

done

echo -e "\n"
