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

function gather_txids() {
# Wait and notify user if they are not yet funded
echo "gather TXID"
}

function install_mns() {

        cd $INSTALLDIR/nodemaster || exit
        echo -e "Invoking local Nodemaster's VPS script to add additional masternodes" | tee -a "$LOGFILE"
        echo -e "Launching Nodemaster using bash install.sh -n $ONLYNET -p $PROJECT" -c "$TNODES" | tee -a "$LOGFILE"
        sudo bash install.sh -n $ONLYNET -p "$PROJECT" -c "$TNODES"
        echo -e "\n"

        # check for presence of config file to presume success, cancel and report error if does not exist

        # activate masternodes, or activate just FIRST masternode
        echo -e "Activating your $PROJECTt masternode(s)" | tee -a "$LOGFILE"
        ###### substitute in genkeys before starting them
        # activate_masternodes_"$PROJECT" echo -e | tee -a "$LOGFILE"

        # check if $PROJECTd was built correctly and started
        if ps -A | grep "$MNODE_BINARIES" > /dev/null
        then
            # report back to mother
            if [ -e "$INFODIR"/fullauto.info ] ; then echo -e "Reporting ${MNODE_BINARIES} build success to mother" | tee -a "$LOGFILE" ; curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Process '"$MNODE_DAEMON"' has started ..."}' && echo -e " " ; fi

        else
            for ((H=1;H<=10;H++));
            do
                if ps -A | grep "$MNODE_BINARIES" > /dev/null
                then
                    # report back to mother
                    if [ -e "$INFODIR"/fullauto.info ] ; then echo -e "Reporting ${MNODE_BINARIES} build success to mother" | tee -a "$LOGFILE" ; curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Process '"$MNODE_DAEMON"' started after '"$H"' seconds ..."}' && echo -e " " ; fi
                    break
                else

                    if [ "${H}" = "10" ]
                    then echo " "
                        echo -e "After $H (H) seconds, $MNODE_DAEMON is still not running" | tee -a "$LOGFILE"
                        echo -e "so we are going to abort this installation now. \n" | tee -a "$LOGFILE"
                        echo -e "Reporting ${MNODE_DAEMON} build failure to mother" | tee -a "$LOGFILE"
                        if [ -e "$INFODIR"/fullauto.info ] ; then curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Error: '"$MNODE_DAEMON"' failed to build or start after 10 seconds"}' && echo -e " " ; fi
                        exit
                    fi
                    sleep 1
                fi
            done
        fi
}

function change_vpsnumber() {
echo "change vpsnumber"

}


function create_genkeys() {
# create new MN genkeys

        echo -e "Creating masternode.conf variables and files for $MNS masternodes" | tee -a "$LOGFILE"
        for ((i=($MNS+1);i<=$TNODES;i++));
        do
            for ((P=1;P<=35;P++));
            do
                # create masternode genkeys (smart is special "smartnodes")
                if [ -e $INSTALLDIR/temp/bogus ] ; then :
                elif [ "${PROJECT,,}" = "smart" ] ; then /usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n1.conf smartnode genkey >> $INFODIR/vpsgenkeys.info
                elif [ "${PROJECT,,}" = "pivx" ] ; then /usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n1.conf createmasternodekey >> $INFODIR/vpsgenkeys.info
                elif [ "${PROJECT,,}" = "zcoin" ] ; then /usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n1.conf znode genkey >> $INFODIR/vpsgenkeys.info
                else /usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}"_n1.conf masternode genkey >> $INFODIR/vpsgenkeys.info ; fi
                echo -e "$(sed -n ${i}p $INFODIR/vpsgenkeys.info)" > $INSTALLDIR/temp/GENKEY$i

                if [ "${PROJECT,,}" = "smart" ] ; then echo "smartnodeprivkey=" > $INSTALLDIR/temp/MNPRIV1
                elif [ "${PROJECT,,}" = "zcoin" ] ; then echo "znodeprivkey=" > $INSTALLDIR/temp/MNPRIV1
                else echo "masternodeprivkey=" > $INSTALLDIR/temp/MNPRIV1 ; fi
                KEYXIST=$(<$INSTALLDIR/temp/GENKEY$i)

                # add extra pause for wallets that are slow to start
                if [ "${PROJECT,,}" = "polis" ] ; then SLEEPTIME=15 ; else SLEEPTIME=3 ; fi

                # check if GENKEY variable is empty; if so stop script and report error
                if [ ${#KEYXIST} = "0" ]
                then echo -e " ${MNODE_DAEMON::-1}-cli couldn't create genkey $i; engine likely still starting up"
                    echo -e " --> Waiting for $SLEEPTIME seconds before trying again... loop $P"
                    sleep $SLEEPTIME
                else break
                fi

                if [ ${#KEYXIST} = "0" ] && [ "${P}" = "35" ]
                then echo " "
                    # [ -e $INFODIR/fullauto.info ] && curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "Error: Could not generate masternode genkeys"}' && echo -e " "
                    echo -e "Problem creating masternode $i. Could not obtain masternode genkey." | tee -a "$LOGFILE"
                    echo -e "I patiently tried 35 times but something isn't working correctly.\n" | tee -a "$LOGFILE"
                    exit
                fi
            done
        done


}

# This is where the script actually starts
collect_nnodes
collect_api
collect_addresses
create_genkeys
gather_txids
install_mns
change_vpsnumber




cat $INFODIR/vpsmnaddressTEST.info
sudo rm -rf $INFODIR/vpsmnaddressTEST.info
exit

