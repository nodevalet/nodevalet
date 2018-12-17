#!/bin/bash

# Set Variables
INSTALLDIR='/root/installtemp'
PROJECT=`cat $INSTALLDIR/vpscoin.info`
MNS=`cat $INSTALLDIR/vpsnumber.info`
LOGFILE='/root/installtemp/checkdaemon.log'

# set hostname variable to the name planted by API installation script
	if [ -e /root/installtemp/vpshostname.info ]
	then HNAME=$(</root/installtemp/vpshostname.info)
	else HNAME=`hostname`
	fi
# read number of masternodes that were installed
	if [ -e /root/installtemp/vpsnumber.info ]
	then MNS=$(</root/installtemp/vpsnumber.info)
	else MNS=5
	fi



function get_blocks() {
# echo "grep "blocks" $INSTALLDIR/getinfo_n1" 
BLOCKS=$(grep "blocks" $INSTALLDIR/getinfo_n1 | tr -dc '0-9')
echo -e "Masternode 1 is currently synced through block $BLOCKS.\n"
}

function check_blocksync() {
# set SECONDS+XXXXX to however long is reasonable to let the initial
# chain sync continue before reporting an error back to the user
end=$((SECONDS+7200))

while [ $SECONDS -lt $end ]; do
    echo -e "Time $SECONDS"
    
	rm -rf $INSTALLDIR/getinfo_n1
	touch $INSTALLDIR/getinfo_n1
	/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf getinfo  | tee -a $INSTALLDIR/getinfo_n1
	clear
    
    # if  masternode not running, echo masternode not running and break
    BLOCKS=$(grep "blocks" $INSTALLDIR/getinfo_n1 | tr -dc '0-9')
    echo -e "\n"
    echo -e "$BLOCKS is the current number of blocks"
    
    if (($BLOCKS <= 1 )) ; then echo "Masternode is not syncing" ; break
    else sync_check
    fi
    
    if [ "$SYNCED" = "yes" ]; then printf "${lightcyan}" ; echo "Masternode synced" ; printf "${nocolor}" ; break
    else echo -e "Blockchain not synced; will check again in 10 seconds\n"
    curl -s "http://api.icndb.com/jokes/random" | jq '.value.joke'
    echo -e "\n"
    sleep 10
    fi
done

    if [ "$SYNCED" = "no" ]; then printf "${lightred}" ; echo "Masternode did not sync in allowed time" ; printf "${nocolor}"
    # radio home that blockchain sync was unsuccessful
    # add curl here
    else : ; fi

echo -e "All done."
}

function sync_check() {
CNT=`/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf getblockcount`
# echo -e "CNT is set to $CNT"
HASH=`/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf getblockhash ${CNT}`
#echo -e "HASH is set to $HASH"
TIMELINE1=`/usr/local/bin/helium-cli -conf=/etc/masternodes/helium_n1.conf getblock ${HASH} | grep '"time"'`
TIMELINE=$(echo $TIMELINE1 | tr -dc '0-9')
BLOCKS=$(grep "blocks" $INSTALLDIR/getinfo_n1 | tr -dc '0-9')
# echo -e "TIMELINE is set to $TIMELINE"
LTRIMTIME=${TIMELINE#*time\" : }
# echo -e "LTRIMTIME is set to $LTRIMTIME"
NEWEST=${LTRIMTIME%%,*}
# echo -e "NEWEST is set to $NEWEST"
TIMEDIF=$(echo -e "$((`date +%s`-$NEWEST))")
echo -e "This masternode is $TIMEDIF seconds behind the latest block." 
   #check if current
   if (($TIMEDIF <= 60 && $TIMEDIF >= -60))
	then echo -e "The blockchain is almost certainly synced.\n"
	SYNCED="yes"
	else echo -e "That's the same as $(((`date +%s`-$NEWEST)/3600)) hours or $(((`date +%s`-$NEWEST)/86400)) days behind.\n"
	SYNCED="no"
   fi	
}



for ((i=1;i<=$MNS;i++));
do
echo -e " Checking sync status for masternode "$PROJECT"_n${i}"


# This is where the script actually starts
check_blocksync
# sync_check

# previousBlock=`cat /root/installtemp/blockcount${i}`
# currentBlock=$(/usr/local/bin/"$PROJECT"-cli -conf=/etc/masternodes/"$PROJECT"_n${i}.conf getblockcount)
# /usr/local/bin/"$PROJECT"-cli -conf=/etc/masternodes/"$PROJECT"_n${i}.conf getblockcount > /root/installtemp/blockcount${i}
# if [ "$previousBlock$" == "$currentBlock$" ]; then
# 	echo -e " Previous block is $previousBlock and current block is $currentBlock; same"
# 	echo -e " `date +%m.%d.%Y_%H:%M:%S` : Auto-restarting ${PROJECT}_n${i} because it seems stuck.\n"  | tee -a "$LOGFILE"
#         systemctl stop "$PROJECT"_n${i};
#         sleep 10;
#         systemctl start "$PROJECT"_n${i};
# else echo -e " Previous block is $previousBlock and current block is $currentBlock."
# echo -e " ${PROJECT}_n${i} appears to be syncing normally.\n"
# fi


done




