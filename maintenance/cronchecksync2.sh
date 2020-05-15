#!/bin/bash

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

# set hostname variable to the name planted by API installation script
if [ -e /var/tmp/nodevalet/info/vpshostname.info ]
then HNAME=$(<$INFODIR/vpshostname.info)
else HNAME=$(hostname)
fi

# read or assign number of masternodes that are installed
if [ -e $INFODIR/vpsnumber.info ]
then MNS=$(<$INFODIR/vpsnumber.info)
else MNS=1
fi

# read first argument to string
i=$1

if [ -z "$i" ]
then echo -e "\n $(date +%m.%d.%Y_%H:%M:%S) : Running cronchecksync.sh" | tee -a "$LOGFILE"
    echo -e " cronchecksync.sh was called without an argument and will now exit.\n"  | tee -a "$LOGFILE"
    exit
fi

function sync_check() {
    CNT=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}_n${i}".conf getblockcount)
    HASH=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}_n${i}".conf getblockhash "${CNT}")
    TIMELINE1=$(/usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}_n${i}".conf getblock "${HASH}" | grep '"time"')
    TIMELINE=$(echo "$TIMELINE1" | tr -dc '0-9')
    BLOCKS=$(grep "blocks" $INSTALLDIR/getinfo_n${i} | tr -dc '0-9')
    LTRIMTIME=${TIMELINE#*time\" : }
    NEWEST=${LTRIMTIME%%,*}
    TIMEDIF=$(echo -e "$(($(date +%s)-NEWEST))")
    rm -rf $INSTALLDIR/getinfo_n${i} --force
    if ((TIMEDIF <= 300 && TIMEDIF >= -300))
    then echo -e " The blockchain is almost certainly synced.\n" && SYNCED="yes"
    else SYNCED="no"
    fi
}

function check_blocksync() {

    # echo -e "Time $SECONDS"
    rm -rf $INSTALLDIR/getinfo_n${i}
    touch $INSTALLDIR/getinfo_n${i}
    /usr/local/bin/"${MNODE_DAEMON::-1}"-cli -conf=/etc/masternodes/"${PROJECT}_n${i}".conf getinfo > $INSTALLDIR/getinfo_n${i}

    BLOCKS=$(grep "blocks" $INSTALLDIR/getinfo_n${i} | tr -dc '0-9')
    echo -e "\n${lightcyan}    --> $PROJECTt Masternode $i Sync Status <-- ${nocolor}\n"
    echo -e " The current number of synced blocks is:${yellow} ${BLOCKS}${nocolor}"

    # if masternode is just starting up, log it and move on
    if [ "$BLOCKS" == "1" ]
    then echo -e "${lightred} Masternode ${i} is starting up${nocolor}\n"
        if [ -e $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced ]
        then cp $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastnsync
            rm $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced --force
        fi
        touch $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync
        echo -e "$(date +%m.%d.%Y_%H:%M:%S) -- starting up" >> $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync
        rm -rf $INSTALLDIR/getinfo_n${i} --force
        exit

        # if masternode is not running, check if there's a good reason; if not re-enable it
    elif ! [ "$BLOCKS" ]
    then echo -e "${lightred} Masternode ${i} is not running${nocolor}\n"
        if [ -e $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced ]
        then cp $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastnsync
            rm $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced --force
        fi
        touch $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync
        echo -e "$(date +%m.%d.%Y_%H:%M:%S) -- not running" >> $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync

        # if gettinginfo, exit without writing logs
        if [ -e "$INSTALLDIR/temp/gettinginfo" ]
        then rm -rf $INSTALLDIR/getinfo_n${i} --force
            exit

        elif [ -e "$INSTALLDIR/temp/shuttingdown" ]
        then rm -rf $INSTALLDIR/getinfo_n${i} --force
            exit
        else echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Re-enabling masternode ${PROJECT}_n${i}.\n" | tee -a "$LOGFILE"
            sudo systemctl enable "${PROJECT}"_n${i} > /dev/null 2>&1
            sudo systemctl start "${PROJECT}"_n${i}
            rm -rf $INSTALLDIR/getinfo_n${i} --force
            exit
        fi

        # find out where the sync is at
    else sync_check
    fi

    # resume after running sync_check
    if [ "$SYNCED" = "yes" ]
    then echo -e "${lightgreen} --> Masternode ${PROJECT}_n${i} is synced${nocolor}\n"

        touch $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced

        # if gettinginfo, exit without writing logs
        if [ -e "$INSTALLDIR/temp/gettinginfo" ]
        then rm -rf $INSTALLDIR/getinfo_n${i} --force
            exit
        fi

        echo -e "$(date +%m.%d.%Y_%H:%M:%S)" >> $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced
        rm $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastnsync --force
        if [ -e $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync ]
        then cp $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastosync
            rm $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync --force
        fi
        exit
    else echo -e "${lightred} --> Masternode ${PROJECT}_n${i} is NOT synced${nocolor}\n"

        touch $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync

        # if gettinginfo, exit without writing logs
        if [ -e "$INSTALLDIR/temp/gettinginfo" ]
        then rm -rf $INSTALLDIR/getinfo_n${i} --force
            exit
        fi

        echo -e "$(date +%m.%d.%Y_%H:%M:%S) -- Last block (`cat $INSTALLDIR/temp/blockcount${i}`) is $TIMEDIF seconds old" >> $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync
        rm $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastosync --force
        if [ -e $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced ]
        then cp $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastnsync
            rm $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced --force
        fi
        exit
    fi

    # This file will contain if the chain is currently not synced
    # $INSTALLDIR/temp/"${PROJECT}"_n${i}_nosync  (eg. audax_n2_nosync)

    # This file will contain time of when the chain was fully synced
    # $INSTALLDIR/temp/"${PROJECT}"_n${i}_synced  (eg. audax_n2_synced)

    # This file will contain time of when the chain was last out-of-sync
    # $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastosync  (eg. audax_n2_lastosync)

    # If no longer synced, this file will contain last time chain was synced
    # $INSTALLDIR/temp/"${PROJECT}"_n${i}_lastnsync  (eg. audax_n2_lastnsync)
}

# This is where the script actually starts
check_blocksync

exit
