#!/bin/bash

# Abort script if not running on a NodeValet VPS

# check for presence of vars.sh and run it if it exists, else wget it

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

# check if $POJECT ONLYNET=4, abort if so with warning "Your project only supports 1 masternode per VPS"

# check for possible number of new masternodes
NODES=$(grep MemTotal /proc/meminfo | awk '{print $2 / 1024 / 325}')
MAXNODES=$(echo "$NODES" | awk '{print int($1+0.5)}')
let PNODES=$MAXNODES-$MNS
(($PNODES <= 0)) && echo " ${lightred}This server cannot support any more masternodes${nocolor}\n" && exit

# read first argument to string
NNODES=$1

# if no argument was given, give instructions and ask for one
if [ -z "$NNODES" ]
then clear
    echo -e "\n${white} This scriptlet permits you to add new masternodes to your VPS.\n"
    echo -e " ${lightcyan}This VPS is currently running $MNS masternodes and supports $MAXNODES masternodes"
    echo -e " How many new masternodes would you like to add? ${nocolor}\n"
fi

while :; do
    if [ -z "$NNODES" ] ; then read -p " --> " NNODES ; fi
    [[ $NNODES =~ ^[0-9]+$ ]] || { printf "${lightred}"; echo -e "\n --> I only recognize numbers; enter a number between 0 and $PNODES...\n"; t=""; printf "${nocolor}"; continue; }
    if (($NNODES >= 0 && $NNODES <= $PNODES)); then break
    else echo -e "\n${lightred} --> That's too many; please enter a number between 0 and $PNODES.${nocolor}\n"
        NNODES=""
    fi
done


# Gather new MN addresses
echo -e "\n\n Next, we need to collect your $NNODES new masternode address(es)."

        cp $INFODIR/vpsmnaddress.info $INFODIR/vpsmnaddressTEST.info

        for ((i=1;i<=$NNODES;i++));
        do
            while :; do
                echo -e "\n${cyan} Please enter the $PROJECTt address for new masternode #$i${nocolor}"
                read -p "  --> " MNADDP
                echo -e "\n You entered the address: ${MNADDP} "
                read -n 1 -s -r -p "${cyan}  --> Is this correct? y/n  ${nocolor}" VERIFY
                echo " "
                if [[ $VERIFY == "y" || $VERIFY == "Y" || $VERIFY == "yes" || $VERIFY == "Yes" ]]
                then break
                fi
            done
            
            echo -e "$MNADDP" >> $INFODIR/vpsmnaddressTEST.info
            echo -e " -> New masternode $i address is: $MNADDP"
            let NNUMBER=$MNS+$i
            echo -e " This will be masternode #$NNUMBER on this VPS\n"
        done

# This is where the script actually starts
# check_blocksync

exit
