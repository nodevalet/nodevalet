#!/bin/bash
# SmartStart manages masternode startup after the system reboots

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

# cleanup old maintenance files
rm -f $INSTALLDIR/temp/checkingdaemon
rm -f $INSTALLDIR/temp/bootstrapping
rm -f $INSTALLDIR/temp/shuttingdown
rm -f $INSTALLDIR/temp/clonesyncing
rm -f $INSTALLDIR/temp/gettinginfo
rm -f $INSTALLDIR/temp/activating

clear

# exit if there is only one masternode
if [ $MNS = 1 ]
then echo -e " This VPS has only one masternode, not running smartstart.sh\n"
    exit
fi

echo -e "\n"
echo -e " $(date +%m.%d.%Y_%H:%M:%S) : ${lightcyan}Server reboot detected; running smartstart.sh${nocolor}" | tee -a "$LOGFILE"
echo -e " --> NodeValet SmartStart will reduce server congestion after each reboot\n"  | tee -a "$LOGFILE"

# extglob was necessary to make rm -- ! possible
# shopt -s extglob

touch $INSTALLDIR/temp/updating
touch $INSTALLDIR/temp/smartstart

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
    echo -e "\n${yellow} SmartStart will now stop and disable all masternode(s):${nocolor}\n"
    for ((i=1;i<=$MNS;i++));
    do
        echo -e "${lightred} Stopping and disabling masternode ${PROJECT}_n${i}...${nocolor}"
        # systemctl disable "${PROJECT}"_n${i} > /dev/null 2>&1
        # systemctl stop "${PROJECT}"_n${i}
        . /var/tmp/nodevalet/maintenance/mnstop.sh $i &
    done
    echo -e "${white} Sleeping for 4 minutes to give masternodes time to stop...${nocolor}"
    sleep 240
    echo -e "${lightcyan} --> All masternodes have been stopped and disabled${nocolor}\n"
}

function restart_mns() {
    # restart and re-enable all masternodes
    echo -e "${yellow} SmartStart will now intelligently restart all masternodes:${nocolor}"
    
    # restart the rest of the unsynced masternodes
    for ((i=1;i<=$MNS;i++));
    do
        echo -e -n "${white}  Restarting masternode ${PROJECT}_n${i}...${nocolor}"
        systemctl enable "${PROJECT}"_n${i} > /dev/null 2>&1
        systemctl start "${PROJECT}"_n${i}
        let "stime=$i"
        echo -e " (waiting${lightpurple} ${stime}s ${nocolor}for restart)"

        # display countdown timer on screen
        seconds=$stime; date1=$((`date +%s` + $seconds));
        while [ "$date1" -ge `date +%s` ]; do
            echo -ne "          $(date -u --date @$(($date1 - `date +%s` )) +%H:%M:%S)\r";
            sleep 0.5
        done

        # check if masternode has fully started up and is synced
        checksync $i
        echo -e "${yellow} Checking if masternode ${PROJECT}_n$i is synced.${nocolor}\n"
        sudo bash $INSTALLDIR/maintenance/cronchecksync2.sh $i > /dev/null 2>&1
    done
    echo -e "${lightcyan} --> All masternodes have been restarted and enabled${nocolor}\n"
}

# this is the actual start of the script
remove_crons_function
shutdown_mns
restart_mns
restore_crons_function

echo -e "\n${lightgreen} Complete; all masternodes have been intelligently restarted.${nocolor}\n"
echo -e " $(date +%m.%d.%Y_%H:%M:%S) : ${lightgreen}SmartStart has completed; resuming normal operations!${nocolor}\n" >> $LOGFILE
rm -f $INSTALLDIR/temp/updating
rm -f $INSTALLDIR/temp/smartstart
exit
