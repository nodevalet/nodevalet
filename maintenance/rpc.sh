#!/bin/bash

# exit with error if not run as root/sudo
if [ "$(id -u)" != "0" ]
then echo -e "\n Please re-run as root or sudo.\n"
    exit 1
fi

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

# read or assign number of masternodes that are installed
if [ -e $INFODIR/vps.number.info ]
then MNS=$(<$INFODIR/vps.number.info)
else MNS=1
fi

# read first argument to string
i="$1"
c="$2"

# if both arguments are not given, give instructions and ask for them

if [ -z "$i" ]
then clear
    echo -e "${lightcyan}\n This scriptlet will execute rpc commands on a masternode."
    echo -e " Which masternode would you like to interact with? ${nocolor}\n"

fi

while :; do
    if [ -z "$i" ] ; then read -p " --> " i ; fi
    [[ $i =~ ^[0-9]+$ ]] || { echo -e "{lightred}\n --> I only recognize numbers; enter a number between 1 and $MNS...${nocolor}\n"; i=""; continue; }
    if ((i >= 1 && i <= MNS)); then break
    else echo -e "\n${lightred} --> I can't find masternode $i; enter a number between 1 and $MNS.${nocolor}\n"
        i=""
    fi
done

if [ -z "$c" ]
then clear
    echo -e "${lightcyan}\n What is the RPC command you wish to issue? ${nocolor}\n"
fi

while :; do
    if [ -z "$c" ] ; then read -p " --> " c ; fi
    if [ ${#c} -ge 2 ] ; then break
    else echo -e "\n${lightred} --> Please enter a valid RPC command or enter 'help'.${nocolor}\n"
        c=""
    fi
done
echo " "
echo -e "${white} Running command: ${yellow}/usr/local/bin/${MNODE_DAEMON::-1}-cli -conf=/etc/masternodes/${PROJECT}_n${i}.conf $c${nocolor}"
echo -e "${white} "
/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}_n${i}".conf $c
echo -e "${nocolor} "
exit
