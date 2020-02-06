#!/bin/bash

LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
MNS=$(<$INFODIR/vpsnumber.info)
PROJECT=$(<$INFODIR/vpscoin.info)
PROJECTl=${PROJECT,,}
PROJECTt=${PROJECTl~}
MNODE_DAEMON=$(<$INFODIR/vpsmnode_daemon.info)
HNAME=$(<$INFODIR/vpshostname.info)

# read or set project variables
if [ -s $INFODIR/vpscoin.info ]
then PROJECT=$(cat $INFODIR/vpscoin.info)
    MNS=$(cat $INFODIR/vpsnumber.info)
else PROJECT='none'
    MNS='10'
fi

touch $INSTALLDIR/temp/updating
echo -e "\n"
echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Running swapedit.sh to quickly edit swap size.\n" | tee -a "$LOGFILE"

# read first argument to string
i=$1

# validate input
if [ -z "$i" ]
then clear
    echo -e "\n It looks like you're trying to edit your swap file."
    echo -e " How large would you like your swap to be? Enter 1 for 1GB, 2 for 2GB, etc.\n"
fi

while :; do
    if [ -z "$i" ] ; then read -p "  --> " i ; fi
    [[ $i =~ ^[0-9]+$ ]] || { printf "${lightred}";echo -e " --> I only recognize numbers, try again..."; i=""; continue; }
    if (($i >= 1 && $i <= $MNS)); then break
    else echo -e "\n --> That's too big, try a number equal to or smaller than $MNS. \n"
        i=""
    fi
done

# prompt to shut down masternodes if they're installed
if [ -s $INFODIR/vpscoin.info ]
then
    while :; do
        printf "${cyan}"
        echo -e "\n Changes to the swap file require briefly shutting down your masternodes."
        read -n 1 -s -r -p "  --> Would you like to do this now and then restart them after? y/n  " VERIFY
        if [[ $VERIFY == "y" || $VERIFY == "Y" ]]
        then echo -e "\n"
            printf "${cyan}" ; break
    elif [[ $VERIFY == "n" || $VERIFY == "N" ]]
        echo -e "\n"
        echo -e " Exiting the script; you cannot change swap size without stopping masternodes.\n"  | tee -a "$LOGFILE"
        rm -rf $INSTALLDIR/temp/updating
        then exit
        fi
    done
    killswitch
else
    echo -e "There are no running masternodes so no need to shut anything down.\n"
fi

sudo swapoff -a -v && sudo rm /swapfile && sudo cp /etc/fstab /etc/fstab.bak && sudo sed -i '/\/swapfile/d' /etc/fstab
sleep 2
fallocate -l ${i}G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile && cp /etc/fstab /etc/fstab.bak && echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

echo -e "\n"
echo -e  " User has set the size of the swap file to ${i}G.\n"  | tee -a "$LOGFILE"

# restart masternodes if they exist
if [ -s $INFODIR/vpscoin.info ]
then echo -e " Restarting all masternode."
    activate_masternodes_${PROJECT}
    echo -e " Waiting 10 seconds before I move on."
    sleep 10
else echo -e "There are no masternodes so no need to restart anything.\n"
fi

echo -e " Unsetting -update flag \n"
rm -f $INSTALLDIR/temp/updating

echo -e " Your changes to the swap file are now complete \n"
