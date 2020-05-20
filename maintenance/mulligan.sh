#!/bin/bash
# This script will scrub NodeValet from your VPS

# exit with error if not run as root/sudo
if [ "$(id -u)" != "0" ]
then echo -e "\n Please re-run as root or sudo.\n"
    exit 1
fi

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

# extglob was necessary to make rm -- ! possible
shopt -s extglob

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
        touch $INSTALLDIR/temp/smartstart
        for ((i=1;i<=$MNS;i++));
        do
            echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Stopping and disabling masternode ${PROJECT}_n${i}"
            
            . /var/tmp/nodevalet/maintenance/mnstop.sh $i &
        done
        sleep 20
        echo -e "\n"
        rm -rf $INSTALLDIR/temp/smartstart
        for ((i=1;i<=$MNS;i++));
        do  
            find / -name "${PROJECT}_n${i}.service" -delete
        done
        echo -e "------------------------------------------------------------------\n"

        echo -e "\n${yellow}-------------------------------------------------------------------- "
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Removing all masternodes and blockchain data"
        echo -e "-------------------------------------------------------------------- ${white}\n"
        rm -rf /var/lib/masternodes
        rm -rf /etc/masternodes

        echo -e "${lightgreen}----------------------------------------------------------------------------- "
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : SUCCESS : Masternodes have been stopped and destroyed"
        echo -e "----------------------------------------------------------------------------- ${yellow}\n"

        echo -e "${yellow}--------------------------------------------------------------------------- "
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Removing all files from /usr/local/bin and rc.local"
        echo -e "--------------------------------------------------------------------------- ${white}\n"
        rm -rf /usr/local/bin/*
        rm -rf /root/.${PROJECT}
        rm -rf /etc/rc.local

while :; do
    printf "${cyan}"
    echo -e " Installation variables and data are stored in the nvtemp folder.${nocolor}\n"
    read -n 1 -s -r -p "  --> Would you like to remove this folder now? y/n  " VERIFY
    if [[ $VERIFY == "y" || $VERIFY == "Y" ]]
    then echo -e "\n"
        echo -e "${yellow}------------------------------------------------------- "
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Removing folder /var/tmp/nvtemp"
        echo -e "------------------------------------------------------- ${white}\n"
        sudo rm -rf /var/tmp/nvtemp
    break
    elif [[ $VERIFY == "n" || $VERIFY == "N" ]]
    then echo -e "\n"
    break
    fi
done

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
