#!/bin/bash
# This script will scrub NodeValet from your VPS

LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
MNS=$(<$INFODIR/vpsnumber.info)
PROJECT=$(<$INFODIR/vpscoin.info)
PROJECTl=${PROJECT,,}
PROJECTt=${PROJECTl~}
MNODE_DAEMON=$(<$INFODIR/vpsmnode_daemon.info)
HNAME=$(<$INFODIR/vpshostname.info)

# extglob was necessary to make rm -- ! possible
shopt -s extglob

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

function search_and_destroy() {

    echo -e -n "${yellow}"
    clear
    echo -e "-------------------------------------------- "
    echo -e " $(date +%m.%d.%Y_%H:%M:%S) : PURGE NODEVALET DATA "
    echo -e "-------------------------------------------- \n"
    echo -e -n "${lightcyan}"
    echo -e " This scriptlet will disable your masternodes on this VPS and "
    echo -e " destroy all NodeValet data. It is intended for testing only.\n"

    echo -e " ** DO NOT USE THIS IN PRODUCTION UNLESS YOU REALLY MEAN TO **"
    # echo -e -n "${cyan}"
    while :; do
        echo -e "\n"
        read -n 1 -s -r -p " ${lightred}Would you like to destroy all masternodes now? y/n " NUKEIT
        if [[ ${NUKEIT,,} == "y" || ${NUKEIT,,} == "Y" || ${NUKEIT,,} == "N" || ${NUKEIT,,} == "n" ]]
        then
            break
        fi
    done
    echo -e "${nocolor}"

    if [ "${NUKEIT,,}" = "Y" ] || [ "${NUKEIT,,}" = "y" ]
    then
        # set mnode daemon name from project.env
        MNODE_DAEMON=$(grep ^MNODE_DAEMON $INSTALLDIR/nodemaster/config/"${PROJECT}"/"${PROJECT}".env)
        echo -e "$MNODE_DAEMON" > $INSTALLDIR/temp/MNODE_DAEMON
        sed -i "s/MNODE_DAEMON=\${MNODE_DAEMON:-\/usr\/local\/bin\///" $INSTALLDIR/temp/MNODE_DAEMON  2>&1
        cat $INSTALLDIR/temp/MNODE_DAEMON | tr -d '[}]' > $INSTALLDIR/temp/MNODE_DAEMON1
        MNODE_DAEMON=$(<$INSTALLDIR/temp/MNODE_DAEMON1)
        cat $INSTALLDIR/temp/MNODE_DAEMON1 > $INSTALLDIR/temp/MNODE_DAEMON ; rm -f $INSTALLDIR/temp/MNODE_DAEMON1
        # mnode daemon name has been set

        echo -e "\n${yellow}--------------------------------------------- "
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Removing all crontabs"
        echo -e "--------------------------------------------- ${white}\n"
        crontab -r

        echo -e "${yellow}---------------------------------------------------------- "
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Stopping and disabling masternodes"
        echo -e "---------------------------------------------------------- ${white}\n"

        echo -e "${yellow}------------------------------------------------------------------ "
        for ((i=1;i<=$MNS;i++));
        do
            echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Stopping and disabling masternode ${PROJECT}_n${i}"
            systemctl disable "${PROJECT}"_n${i}
            systemctl stop "${PROJECT}"_n${i}
        done
        echo -e "------------------------------------------------------------------------------ ${white}\n"
        sleep 2

        echo -e "${yellow}-------------------------------------------------------------------- "
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Removing all masternodes and blockchain data"
        echo -e "-------------------------------------------------------------------- ${white}\n"
        rm -rf /var/lib/masternodes
        rm -rf /etc/masternodes

        echo -e "${lightgreen}----------------------------------------------------------------------------- "
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : SUCCESS : Masternodes have been stopped and destroyed"
        echo -e "----------------------------------------------------------------------------- ${yellow}\n"

        echo -e "${yellow}-------------------------------------------------------------- "
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Removing all files from /usr/local/bin"
        echo -e "-------------------------------------------------------------- ${white}\n"
        rm -rf /usr/local/bin/*

        echo -e "${yellow}------------------------------------------------------- "
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Removing folder /var/tmp/nvtemp"
        echo -e "------------------------------------------------------- ${white}\n"
        sudo rm -rf /var/tmp/nvtemp

        echo -e "${yellow}-------------------------------------------------------- "
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Stopping and disabling swap file"
        echo -e "-------------------------------------------------------- ${white}\n"
        sudo swapoff -a -v > /dev/null 2>&1 && sudo rm /swapfile && sudo cp /etc/fstab /etc/fstab.bak && sudo sed -i '/\/swapfile/d' /etc/fstab

        echo -e "${yellow}------------------------------------------------------------------ "
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Removing all files from /var/tmp/nodevalet"
        echo -e "------------------------------------------------------------------ ${white}\n"
        sudo rm -rf /var/tmp/nodevalet

        echo -e "${lightgreen}------------------------------------------------------------------------- "
        echo " $(date +%m.%d.%Y_%H:%M:%S) : SUCCESS : NodeValet was scrubbed from this Server"
        echo -e "------------------------------------------------------------------------- ${nocolor}\n"

    else :
        echo -e "${yellow}---------------------------------------------------- "
        echo -e "     ** User elected not destroy and wipe this VPS ** "
        echo -e "----------------------------------------------------${nocolor}\n"
    fi
}

search_and_destroy
cd /var/tmp

exit
