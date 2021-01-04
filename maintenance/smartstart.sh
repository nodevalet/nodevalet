#!/bin/bash
# SmartStart manages masternode startup after the system reboots

# exit with error if not run as root/sudo
if [ "$(id -u)" != "0" ]
then echo -e "\n Please re-run as root or sudo.\n"
    exit 1
fi

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

# cleanup old maintenance files
rm -f $INSTALLDIR/temp/checkingdaemon
rm -f $INSTALLDIR/temp/bootstrapping
rm -f $INSTALLDIR/temp/shuttingdown
rm -f $INSTALLDIR/temp/clonesyncing
rm -f $INSTALLDIR/temp/gettinginfo
rm -f $INSTALLDIR/temp/activating
rm -f $INSTALLDIR/temp/updating

clear

# exit if there is only one or two masternode(s)
if [ $MNS = 1 ] || [ $MNS = 2 ]
then echo -e " This VPS has only one or two masternodes; not running smartstart.sh\n"
    exit
fi

echo -e "\n"
echo -e " $(date +%m.%d.%Y_%H:%M:%S) : ${lightcyan}Server reboot detected; running smartstart.sh${nocolor}" | tee -a "$LOGFILE"
echo -e " --> NodeValet SmartStart will reduce server congestion after each reboot\n"  | tee -a "$LOGFILE"

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
        . /var/tmp/nodevalet/maintenance/mnstop.sh $i &
    done
    echo -e "${white} Sleeping for 4 minutes to give masternodes time to stop...${nocolor}"
    
    # display countdown timer on screen
    seconds=240; date1=$((`date +%s` + $seconds));
    while [ "$date1" -ge `date +%s` ]; do
        echo -ne "          $(date -u --date @$(($date1 - `date +%s` )) +%H:%M:%S)\r";
        sleep 0.5
    done
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
        let "stime=5"
        let "j=$i+1"

    if (($j <= $MNS))
    then echo -e " "
        echo -e -n "${white}  Restarting masternode ${PROJECT}_n${j}...${nocolor}"
        systemctl enable "${PROJECT}"_n${j} > /dev/null 2>&1
        systemctl start "${PROJECT}"_n${j}
    fi

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

        if (($j <= $MNS))
        then checksync $j
            echo -e "${yellow} Checking if masternode ${PROJECT}_n$j is synced.${nocolor}\n"
            touch "$INSTALLDIR/temp/gettinginfo"
            sudo bash $INSTALLDIR/maintenance/cronchecksync2.sh $j > /dev/null 2>&1
            rm -rf "$INSTALLDIR/temp/gettinginfo"
        fi

    let "i=$i+1"
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
