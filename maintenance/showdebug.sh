#!/bin/bash
# This script will display the masternode debug log for a particular masternode

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

# extglob was necessary to make rm -- ! possible
shopt -s extglob

# read first argument to string
i=$1

# verify that this is a NodeValet.io configured VPS
if [ -z $PROJECT ]
then clear
    echo -e "\n This is not a VPS that was configured by NodeValet and"
    echo -e " as a result, there is no debug log to display. \n"
    echo -e "\n Did you expect something different? Let us know.\n"
    exit
else cd $INSTALLDIR
fi

# if no argument was given, give instructions and ask for one

if [ -z "$i" ]
then clear
    echo -e "\n This scriptlet will display the debug log for a particular node."
    echo -e " Which masternode would you like to debug? \n"
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


clear
echo -e "\n"
cat $INSTALLDIR/masternode.conf
cat /var/lib/masternodes/${PROJECT}${i}/debug.log
echo -e "\n"
