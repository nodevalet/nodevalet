#!/bin/bash
# Clonesync all masternodes, assumes 1 is fully synced

LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
MNS=$(<$INFODIR/vpsnumber.info)
PROJECT=$(<$INFODIR/vpscoin.info)
PROJECTl=${PROJECT,,}
PROJECTt=${PROJECTl~}
MNODE_DAEMON=$(<$INFODIR/vpsmnode_daemon.info)
HNAME=$(<$INFODIR/vpshostname.info)

clear

echo -e "\n"
echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Running clonesync_all.sh" | tee -a "$LOGFILE"
echo -e " --> Attempting to bootstrap all Masternodes using n1's blockchain"  | tee -a "$LOGFILE"

### define colors ###
lightred=$'\033[1;31m'  # light red
red=$'\033[0;31m'  # red
lightgreen=$'\033[1;32m'  # light green
green=$'\033[0;32m'  # green
lightblue=$'\033[1;34m'  # light blue
blue=$'\033[0;34m'  # blue
lightpurple=$'\033[1;35m'  # light purple
purple=$'\033[0;35m'  # purple
lightcyan=$'\033[1;36m'  # light cyan
cyan=$'\033[0;36m'  # cyan
lightgray=$'\033[0;37m'  # light gray
white=$'\033[1;37m'  # white
brown=$'\033[0;33m'  # brown
yellow=$'\033[1;33m'  # yellow
darkgray=$'\033[1;30m'  # dark gray
black=$'\033[0;30m'  # black
nocolor=$'\e[0m' # no color

# extglob was necessary to make rm -- ! possible
shopt -s extglob

touch $INSTALLDIR/temp/updating

function remove_crons() {
    # disable the crons that could cause problems
    crontab -l | grep -v '/var/tmp/nodevalet/maintenance/rebootq.sh'  | crontab -
    crontab -l | grep -v '/var/tmp/nodevalet/maintenance/makerun.sh'  | crontab -
    crontab -l | grep -v '/var/tmp/nodevalet/maintenance/checkdaemon.sh'  | crontab -
    crontab -l | grep -v '/var/tmp/nodevalet/maintenance/rebootq.sh'  | crontab -
    crontab -l | grep -v '/var/tmp/nodevalet/maintenance/autoupdate.sh'  | crontab -
}

function shutdown_mns() {
    # shutdown all MNs except the first
    echo -e "\n${yellow} Clonesync_all will now stop and disable all Target masternode(s):${nocolor}"
    for ((i=2;i<=$MNS;i++));
    do
        echo -e "${lightred}  Stopping and disabling masternode ${PROJECT}_n${i}...${nocolor}"
        systemctl disable "${PROJECT}"_n${i} > /dev/null 2>&1
        systemctl stop "${PROJECT}"_n${i}
    done
    echo -e "${lightcyan} --> Masternodes have been stopped and disabled${nocolor}\n"
}

function adjust_swap() {
    # reserved for future user
    true
}

function checksync_source() {
    touch $INSTALLDIR/temp/clonesyncing
    # wait for sync and then make sure masternode 1 has a fully-synced blockchain
    checksync 1
    echo -e "${yellow} Checking if masternode ${PROJECT}_n1 is synced.${nocolor}\n"
    sudo bash $INSTALLDIR/maintenance/cronchecksync2.sh 1 > /dev/null 2>&1
    sleep .5
    SOURCESYNC=$(ls /var/tmp/nodevalet/temp | grep "${PROJECT}_n1" | grep "synced")
    if [[ "${SOURCESYNC}" ]]
    then echo -e "${lightgreen} Masternode ${PROJECT}_n1 is synced and a valid Source masternode.${nocolor}"
        echo -e "${lightcyan} --> Setting Source masternode to n1${nocolor}\n"
        rm -f $INSTALLDIR/temp/clonesyncing
        s=1
    else echo -e " Source (${PROJECT}_n1) is not synced; aborting clonesync_all.\n"  | tee -a "$LOGFILE"
        rm -f $INSTALLDIR/temp/updating
        rm -f $INSTALLDIR/temp/clonesyncing
        restore_crons
        activate_masternodes_"$PROJECT"
        exit
    fi
}

function shutdown_mn1() {
    # stop and disable mn1
    echo -e "${yellow} Clonesync_all needs to shut down the Source masternode:${nocolor}"
    # echo -e "${lightred} Disabling Source masternode ${PROJECT}_n1 now."
    sudo systemctl disable "${PROJECT}"_n1 > /dev/null 2>&1
    sudo systemctl stop "${PROJECT}"_n1
    rm -f $INSTALLDIR/temp/"${PROJECT}"_n1_synced
    echo -e " ${lightred}--> Masternode ${PROJECT}_n1 has been disabled...${nocolor}\n"
}

function bootstrap() {
    # copy blocks/chainstate/sporks from n1 to all masternodes
    echo -e "${yellow} Clonesync_all will now remove relevant blockchain data from target(s):${nocolor}"
    for ((t=2;t<=$MNS;t++));
    do
        echo -e "${lightred}  Clearing blockchain from ${PROJECT}_n$t...${nocolor}"
        cd /var/lib/masternodes/"${PROJECT}"${t}
        sudo rm -rf !("wallet.dat"|"masternode.conf")
        sleep .25
    done
    echo -e "${lightcyan} --> All blockchain data has been cleared from the target(s)${nocolor}\n"

    echo -e "${yellow} Clonesync_all will now copy n1's blockchain data to target masternode(s):${nocolor}"
    for ((t=2;t<=$MNS;t++));
    do
        # copy blocks/chainstate/sporks with permissions (cp -rp) or it will fail
        echo -e "${white}  Copying blockchain data to ${PROJECT}_n$t...${nocolor}"
        cd /var/lib/masternodes/"${PROJECT}"${s}
        cp -rp /var/lib/masternodes/"${PROJECT}${s}"/blocks /var/lib/masternodes/"${PROJECT}${t}"/blocks
        cp -rp /var/lib/masternodes/"${PROJECT}${s}"/chainstate /var/lib/masternodes/"${PROJECT}${t}"/chainstate
        cp -rp /var/lib/masternodes/"${PROJECT}${s}"/sporks /var/lib/masternodes/"${PROJECT}${t}"/sporks
        # copy weird bootstraps like Phore; edit: don't do thiS! No need to copy bootstrap.dat since blocks are unpacked
        # if [ -s /var/lib/masternodes/"${PROJECT}${s}"/bootstrap.dat ]
        # then cp -p /var/lib/masternodes/"${PROJECT}${s}"/bootstrap.dat /var/lib/masternodes/"${PROJECT}${t}"/
        # else :
        # fi
    done
    echo -e "${lightcyan} --> All masternodes have been bootstrapped from ${PROJECT}_n1${nocolor}\n"
}

function restart_mns() {
    # restart and re-enable all masternodes
    echo -e "${yellow} Clonesync_all will now restart all masternodes:${nocolor}"
    for ((i=1;i<=$MNS;i++));
    do
        echo -e -n "${white}  Restarting masternode ${PROJECT}_n${i}...${nocolor}"
        systemctl enable "${PROJECT}"_n${i} > /dev/null 2>&1
        systemctl start "${PROJECT}"_n${i}
        let "stime=5*$i"
        echo -e " (waiting${lightpurple} ${stime}s ${nocolor}for restart)"
        sleep $stime
    done
    echo -e "${lightcyan} --> Masternodes have been restarted and enabled${nocolor}\n"
}

function restore_crons() {
    # restore maintenance crons that were previously disabled
    echo -e "${yellow} Re-enabling crontabs that were previously disabled:${nocolor}"
    echo -e "${white}  --> Check for & reboot if needed to install updates every 10 hours${nocolor}"
    (crontab -l ; echo "59 */10 * * * /var/tmp/nodevalet/maintenance/rebootq.sh") | crontab -
    echo -e "${white}  --> Make sure all daemons are running every 10 minutes${nocolor}"
    (crontab -l ; echo "*/10 * * * * /var/tmp/nodevalet/maintenance/makerun.sh") | crontab -
    echo -e "${white}  --> Check for stuck blocks every 30 minutes${nocolor}"
    (crontab -l ; echo "1,31 * * * * /var/tmp/nodevalet/maintenance/checkdaemon.sh") | crontab -
    echo -e "${white}  --> Check for & reboot if needed to install updates every 10 hours${nocolor}"
    (crontab -l ; echo "59 */10 * * * /var/tmp/nodevalet/maintenance/rebootq.sh") | crontab -
    echo -e "${white}  --> Check for wallet updates every 48 hours${nocolor}"
    (crontab -l ; echo "2 */48 * * * /var/tmp/nodevalet/maintenance/autoupdate.sh") | crontab -
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
remove_crons
shutdown_mns
adjust_swap
checksync_source
shutdown_mn1
bootstrap
restart_mns
restore_crons

echo -e "\n${lightgreen} Complete; Masternodes have all been bootstrapped.${nocolor}\n"
echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Masternodes have all been bootstrapped!\n" >> $LOGFILE
rm -f $INSTALLDIR/temp/updating
exit