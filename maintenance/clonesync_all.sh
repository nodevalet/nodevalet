#!/bin/bash
# Clonesync all masternodes, assumes 1 is fully synced

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

clear

# exit if there is only one masternode
if [ $MNS = 1 ]
then echo -e " This VPS has only one masternode, not running clonesync_all.sh\n"  | tee -a "$LOGFILE"
    exit
fi

echo -e "\n"
echo -e " $(date +%m.%d.%Y_%H:%M:%S) : ${lightcyan}Running clonesync_all.sh${nocolor}" | tee -a "$LOGFILE"
echo -e " --> Attempting to bootstrap all Masternodes using n1's blockchain"  | tee -a "$LOGFILE"

# extglob was necessary to make rm -- ! possible
shopt -s extglob

touch $INSTALLDIR/temp/updating

function remove_crons_function() {
    # disable the crons that could cause problems
    . /var/tmp/nodevalet/maintenance/remove_crons.sh
}

function restore_crons_function() {
    # restore maintenance crons that were previously disabled
    . /var/tmp/nodevalet/maintenance/restore_crons.sh
}

function shutdown_mns() {
    # shutdown all MNs except the first
    echo -e "\n${yellow} Clonesync_all will now stop and disable all unsynced masternode(s):${nocolor}\n"
    for ((i=2;i<=$MNS;i++));
    do
    # check for and shutdown masternodes which are not currently synced
    TARGETSYNC=$(ls /var/tmp/nodevalet/temp | grep "${PROJECT}_n${i}" | grep "synced")
    touch $INSTALLDIR/temp/smartstart
    if [[ "${TARGETSYNC}" ]]
    then echo -e "${lightgreen} Masternode ${PROJECT}_n${i} is synced.${nocolor}\n"
    else echo -e "${lightred} Masternode ${PROJECT}_n${i} is not synced.${nocolor}"
        echo -e "${lightred} Stopping and disabling masternode ${PROJECT}_n${i}...${nocolor}"
        . /var/tmp/nodevalet/maintenance/mnstop.sh $i &
    fi
    done
    
    # display countdown timer on screen
    echo -e "${lightcyan} --> Sleeping for 4 minutes to let unsynced masternodes shutdown ${nocolor}\n"
    seconds=240; date1=$((`date +%s` + $seconds));
    while [ "$date1" -ge `date +%s` ]; do
        echo -ne "${lightcyan}   ---> Continuing in:  $(date -u --date @$(($date1 - `date +%s` )) +%H:%M:%S)\r${nocolor}";
        sleep 0.5
    done

    rm -rf $INSTALLDIR/temp/smartstart
    echo -e "${lightcyan} --> Unsynced masternodes have been stopped and disabled${nocolor}\n"
}

function checksync_source() {
    touch $INSTALLDIR/temp/clonesyncing
    # wait for sync and then make sure masternode 1 has a fully-synced blockchain
    checksync 1
    echo -e "${yellow} Checking if masternode ${PROJECT}_n1 is synced.${nocolor}\n"
    touch "$INSTALLDIR/temp/gettinginfo"
    sudo bash $INSTALLDIR/maintenance/cronchecksync2.sh 1 > /dev/null 2>&1
    rm -rf "$INSTALLDIR/temp/gettinginfo"
    sleep 1
    SOURCESYNC=$(ls /var/tmp/nodevalet/temp | grep "${PROJECT}_n1" | grep "synced")

    if [[ "${SOURCESYNC}" ]]
    then :
    else echo -e "${lightred} Source (${PROJECT}_n1) is not yet synced; checking again.${nocolor}\n"
        sleep 30
        checksync 1
        SOURCESYNC=$(ls /var/tmp/nodevalet/temp | grep "${PROJECT}_n1" | grep "synced")
    fi

    if [[ "${SOURCESYNC}" ]]
    then echo -e "${lightgreen} Masternode ${PROJECT}_n1 is synced and a valid Source masternode.${nocolor}"
        echo -e "${lightcyan} --> Setting Source masternode to n1${nocolor}\n"
        rm -f $INSTALLDIR/temp/clonesyncing
        s=1
    else echo -e "${lightred} Source (${PROJECT}_n1) is not synced; aborting clonesync_all.${nocolor}\n"  | tee -a "$LOGFILE"
        rm -f $INSTALLDIR/temp/updating
        rm -f $INSTALLDIR/temp/clonesyncing
        . /var/tmp/nodevalet/maintenance/restore_crons.sh
        activate_masternodes_"$PROJECT"
        exit 1
    fi
}

function shutdown_mn1() {
    # stop and disable mn1
    echo -e "${yellow} Clonesync_all needs to shut down the Source masternode:${nocolor}"
    sudo systemctl disable "${PROJECT}"_n1 > /dev/null 2>&1
    sudo systemctl stop "${PROJECT}"_n1
    sleep 1
    rm -f $INSTALLDIR/temp/"${PROJECT}"_n1_synced
    echo -e " ${lightred}--> Masternode ${PROJECT}_n1 has been disabled...${nocolor}\n"
}

function bootstrap() {
    # copy blocks/chainstate/sporks from n1 to all masternodes
    echo -e "${yellow} Clonesync_all will now remove relevant blockchain data from target(s):${nocolor}"
    for ((t=2;t<=$MNS;t++));
    do
        
    # remove blockchain data from masternodes which were not currently synced
    TARGETSYNC=$(ls /var/tmp/nodevalet/temp | grep "${PROJECT}_n${t}" | grep "synced")
    if [[ "${TARGETSYNC}" ]]
    then :
    else echo -e "${lightred}  Clearing blockchain from ${PROJECT}_n$t...${nocolor}"
        DATAFOLDER=$(find /var/lib/masternodes/${PROJECT}${t} -name "wallet.dat")
            if [ -z "$DATAFOLDER" ]
            then echo -e "${lightred} NodeValet could not locate a wallet.dat file for Masternode ${PROJECT}_n${t}.${nocolor}"
                cd /var/lib/masternodes/"${PROJECT}"${t}
            else echo "$DATAFOLDER" > $INSTALLDIR/temp/DATAFOLDER
                sed -i "s/wallet.dat//" $INSTALLDIR/temp/DATAFOLDER 2>&1
            cd $(cat $INSTALLDIR/temp/DATAFOLDER)
            rm -rf $INSTALLDIR/temp/DATAFOLDER
            fi
        cp wallet.dat wallet_backup.$(date +%m.%d.%y).dat
        sudo rm -rf !("wallet_backup.$(date +%m.%d.%y).dat"|"masternode.conf")
        sleep 1
    fi
    done
    echo -e "${lightcyan} --> All blockchain data has been cleared from unsynced target(s)${nocolor}\n"

    # copy blocks/chainstate/sporks with permissions (cp -rp) or it will fail
    echo -e "${yellow} Clonesync_all will now copy n1's blockchain data to target masternode(s):${nocolor}"
    for ((t=2;t<=$MNS;t++));
    do
    TARGETSYNC=$(ls /var/tmp/nodevalet/temp | grep "${PROJECT}_n${t}" | grep "synced")
    if [[ "${TARGETSYNC}" ]]
    then :
    else echo -e "${white}  Copying blockchain data to ${PROJECT}_n$t...${nocolor}"
        cd /var/lib/masternodes/"${PROJECT}"${s}
        [ -d "/var/lib/masternodes/"${PROJECT}${s}"/blocks" ] && cp -rp /var/lib/masternodes/"${PROJECT}${s}"/blocks /var/lib/masternodes/"${PROJECT}${t}"/blocks
        [ -d "/var/lib/masternodes/"${PROJECT}${s}"/chainstate" ] && cp -rp /var/lib/masternodes/"${PROJECT}${s}"/chainstate /var/lib/masternodes/"${PROJECT}${t}"/chainstate
        [ -d "/var/lib/masternodes/"${PROJECT}${s}"/sporks" ] && cp -rp /var/lib/masternodes/"${PROJECT}${s}"/sporks /var/lib/masternodes/"${PROJECT}${t}"/sporks
        [ -d "/var/lib/masternodes/"${PROJECT}${s}"/zerocoin" ] && cp -rp /var/lib/masternodes/"${PROJECT}${s}"/zerocoin /var/lib/masternodes/"${PROJECT}${t}"/zerocoin
    fi 
    done
    echo -e "${lightcyan} --> Unsynced masternodes have been bootstrapped from ${PROJECT}_n1${nocolor}\n"
}

function restart_mns() {
    # restart and re-enable all masternodes
    echo -e "${yellow} Clonesync_all will now restart all masternodes:${nocolor}"
    
    # restart masternode 1 and wait 5 seconds
    echo -e -n "${white}  Restarting masternode ${PROJECT}_n1...${nocolor}"
        systemctl enable "${PROJECT}"_n1 > /dev/null 2>&1
        systemctl start "${PROJECT}"_n1
        let "stime=5"
        echo -e " (waiting${lightpurple} ${stime}s ${nocolor}for restart)"

        # display countdown timer on screen
        seconds=$stime; date1=$((`date +%s` + $seconds));
        while [ "$date1" -ge `date +%s` ]; do
            echo -ne "          $(date -u --date @$(($date1 - `date +%s` )) +%H:%M:%S)\r";
            sleep 0.5
        done
    
    # restart the rest of the unsynced masternodes
    for ((i=2;i<=$MNS;i++));
    do
    TARGETSYNC=$(ls /var/tmp/nodevalet/temp | grep "${PROJECT}_n${i}" | grep "synced")
    if [[ "${TARGETSYNC}" ]]
    then :
    else echo -e -n "${white}  Restarting masternode ${PROJECT}_n${i}...${nocolor}"
        systemctl enable "${PROJECT}"_n${i} > /dev/null 2>&1
        systemctl start "${PROJECT}"_n${i}
        let "stime=5"

        # display countdown timer on screen
        echo -e " (waiting${lightpurple} ${stime}s ${nocolor}for restart)"
        seconds=$stime; date1=$((`date +%s` + $seconds));
        while [ "$date1" -ge `date +%s` ]; do
            echo -ne "          $(date -u --date @$(($date1 - `date +%s` )) +%H:%M:%S)\r";
            sleep 0.5
        done

        # check if masternode has fully started up and is synced
        checksync $i
        echo -e "${yellow} Checking if masternode ${PROJECT}_n$i is synced.${nocolor}\n"
        touch "$INSTALLDIR/temp/gettinginfo"
        sudo bash $INSTALLDIR/maintenance/cronchecksync2.sh $i > /dev/null 2>&1
        rm -rf "$INSTALLDIR/temp/gettinginfo"
    fi
    done
    echo -e "${lightcyan} --> Unsynced masternodes have been restarted and enabled${nocolor}\n"
}

# This file will contain if the chain is currently not synced
# $INSTALLDIR/temp/"${PROJECT}"_n${t}_nosync  (eg. audax_n2_nosync)

# This file will contain time of when the chain was fully synced
# $INSTALLDIR/temp/"${PROJECT}"_n${t}_synced  (eg. audax_n2_synced)

# This file will contain time of when the chain was last out-of-sync
# $INSTALLDIR/temp/"${PROJECT}"_n${t}_lastosync  (eg. audax_n2_lastoutsync)

# If no longer synced, this file will contain last time chain was synced
# $INSTALLDIR/temp/"${PROJECT}"_n${t}_lastnsync  (eg. audax_n2_lastnsync)

# this is the actual start of the script
remove_crons_function
shutdown_mns
checksync_source
shutdown_mn1
bootstrap
restart_mns
restore_crons_function

echo -e "\n${lightgreen} Complete; unsynced masternodes have been bootstrapped.${nocolor}\n"
echo -e " $(date +%m.%d.%Y_%H:%M:%S) : ${lightgreen}All Masternodes have been bootstrapped!${nocolor}\n" >> $LOGFILE
rm -f $INSTALLDIR/temp/updating
exit
