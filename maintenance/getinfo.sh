#!/bin/bash
# This script will give users the 'getinfo' of installed masternodes

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
        [[ $input =~ ^[0-9]+$ ]] || { printf "${lightred}";echo -e "\n${lightred} I'm sorry; but I only recognize numbers of masternodes on this VPS.\n Which masternode would you like to getinfo on? ${nocolor}\n"; input=""; continue; }
        if (($input >= 1 && $input <= $MNS)); then break
        else echo -e "\n${lightred} --> Can't find masternode $input, try again. ${nocolor}\n"
            input=""
        fi
    done

    # Display 'getinfo' for only the masternode named
    echo -e "\n $(date +%m.%d.%Y_%H:%M:%S) : Displaying select 'getinfo' from Masternode${lightcyan} ${PROJECT}_n${input}${nocolor}"
    touch $INSTALLDIR/temp/gettinginfo
    sudo bash $INSTALLDIR/maintenance/cronchecksync2.sh "$input" > /dev/null 2>&1
    rm -f $INSTALLDIR/temp/gettinginfo
    GETINFO=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n${input}.conf getinfo)
    echo -e "$GETINFO" > GETINFO
    sed '/version\|blocks\|connections/!d' GETINFO > GETINFO2
    cat GETINFO2
    GETINFO3=$(cat GETINFO2)
    rm -f GETINFO
    rm -f GETINFO2

    # check if file exists with name that contains both "audax_n1" and "synced"
    TARGETSYNC=$(ls /var/tmp/nodevalet/temp | grep "${PROJECT}_n${input}_" | grep "synced")
    if [[ "${TARGETSYNC}" ]] && [[ "${GETINFO3}" ]]
    then echo -e "${lightgreen}                     Masternode ${PROJECT}_n${input} is synced.${nocolor}\n"
    else echo -e "${lightred}                     Masternode ${PROJECT}_n${input} is not synced.${nocolor}\n"
    fi
    exit

fi

# Display 'getinfo' for all masternodes
for ((i=1;i<=$MNS;i++));
do
    echo -e "\n $(date +%m.%d.%Y_%H:%M:%S) : Displaying select 'getinfo' from Masternode${lightcyan} ${PROJECT}_n${i}${nocolor}"
    touch $INSTALLDIR/temp/gettinginfo
    sudo bash $INSTALLDIR/maintenance/cronchecksync2.sh "$i" > /dev/null 2>&1
    rm -f $INSTALLDIR/temp/gettinginfo
    GETINFO=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n${i}.conf getinfo)
    echo -e "$GETINFO" > GETINFO
    sed '/version\|blocks\|connections/!d' GETINFO > GETINFO2
    cat GETINFO2

    # check if file exists with name that contains both "audax_n1" and "synced"
    TARGETSYNC=$(ls /var/tmp/nodevalet/temp | grep "${PROJECT}_n${i}_" | grep "synced")
    if [[ "${TARGETSYNC}" ]]
    then echo -e "${lightgreen}                     Masternode ${PROJECT}_n${i} is synced.${nocolor}\n"
    else echo -e "${lightred}                     Masternode ${PROJECT}_n${i} is not synced.${nocolor}\n"
    fi

done
rm -f GETINFO
rm -f GETINFO2

exit