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


function collect_nnodes() {

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

echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Running addmn.sh"  >> $LOGFILE
echo -e " User has requested to add $NNODES new MN(s) to this VPS.\n"  >> $LOGFILE
echo -e "\n Perfect.  We are going to try and add $NNODES new MN(s) to this VPS.\n"
}

function collect_api() {

# read API key if it exists, if not prompt for it

echo -e " Adding $NNODES masternode(s) to your VPS requires 1 NodeValet Deployment credit.\n"
APITEST="https://api.nodevalet.io/txdata.php?coin=audax&address=APKSdh4QyVGGYBLs7wFbo4MjeXwK3GBD1o&key=$VPSAPI"
curl -s "$APITEST" > $INSTALLDIR/temp/API.test.json
APITESTRESPONSE=$(cat $INSTALLDIR/temp/API.test.json)
! [[ "${APITESTRESPONSE}" == "Invalid key" ]] && echo -e "${lightgreen} Your original NodeValet Deployment Key is still valid\n${nocolor}" && rm -f $INSTALLDIR/temp/API.test.json && GOODKEY='true'
    
    if [[ "${GOODKEY}" == "true" ]]
    then :
    else echo -e "${lightred} Your original NodeValet Deployment Key is no longer valid\n${nocolor}"
    echo -e " Before we can begin, we need to collect your NodeValet API Key."
        echo -e "   ! ! Please double check your NodeValet API Key for accuracy ! !"
        rm -rf $INFODIR/vpsapi.info
        touch $INFODIR/vpsapi.info
        echo -e -n " "
        while :; do
            echo -e "\n${cyan} Please enter your NodeValet API Key.${nocolor}"
            read -p "  --> " VPSAPI
            echo -e "\n You entered this API Key: ${VPSAPI} "
            read -n 1 -s -r -p "  ${cyan}--> Is this correct? y/n  ${nocolor}" VERIFY
            if [[ $VERIFY == "y" || $VERIFY == "Y" ]]
            then APITEST="https://api.nodevalet.io/txdata.php?coin=audax&address=APKSdh4QyVGGYBLs7wFbo4MjeXwK3GBD1o&key=$VPSAPI"
                curl -s "$APITEST" > $INSTALLDIR/temp/API.test.json
                APITESTRESPONSE=$(cat $INSTALLDIR/temp/API.test.json)
                ! [[ "${APITESTRESPONSE}" == "Invalid key" ]] && echo -e "${lightgreen}NodeValet API Key is valid${nocolor}" && rm -f $INSTALLDIR/temp/API.test.json && break
                echo -e "${lightred}The API Key you entered is invalid.${nocolor}"
            else echo " "
            fi
        done
        echo -e "$VPSAPI" > $INFODIR/vpsapi.info
        echo -e " NodeValet API Key set to : $VPSAPI" >> $LOGFILE
    fi

}


function collect_addresses() {
# Gather new MN addresses
echo -e "\n\n Next, we need to collect your $NNODES new masternode address or addresses."

        cp $INFODIR/vpsmnaddress.info $INFODIR/vpsmnaddressTEST.info

        let TNODES=$NNODES+$MNS
        for ((i=($MNS+1);i<=$TNODES;i++));
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
            echo -e " -> New masternode $i address is: $MNADDP\n"
        done
}

# This is where the script actually starts
collect_nnodes
collect_api
collect_addresses




cat $INFODIR/vpsmnaddressTEST.info
sudo rm -rf $INFODIR/vpsmnaddressTEST.info
exit

