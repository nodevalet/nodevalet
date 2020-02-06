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

# set mnode daemon name from project.env
MNODE_DAEMON=`grep ^MNODE_DAEMON $INSTALLDIR/nodemaster/config/${PROJECT}/${PROJECT}.env`
echo -e "$MNODE_DAEMON" > $INSTALLDIR/temp/MNODE_DAEMON
sed -i "s/MNODE_DAEMON=\${MNODE_DAEMON:-\/usr\/local\/bin\///" $INSTALLDIR/temp/MNODE_DAEMON  2>&1
cat $INSTALLDIR/temp/MNODE_DAEMON | tr -d '[}]' > $INSTALLDIR/temp/MNODE_DAEMON1
MNODE_DAEMON=$(<$INSTALLDIR/temp/MNODE_DAEMON1)
cat $INSTALLDIR/temp/MNODE_DAEMON1 > $INSTALLDIR/temp/MNODE_DAEMON ; rm -f $INSTALLDIR/temp/MNODE_DAEMON1


# read first argument to string
i=$1

# validate input
if [ -z $i ]
then clear
    echo -e "\n It seems like you're trying to edit a masternode.conf file."
    echo -e " What is the number of the masternode you would like to edit? \n"

fi

while :; do
    if [ -z $i ] ; then read -p "  --> " i ; fi
    [[ $i =~ ^[0-9]+$ ]] || { printf "${lightred}";echo -e " --> I only recognize numbers, try again..."; i=""; continue; }
    if (($i >= 1 && $i <= $MNS)); then break
    else echo -e "\n --> Can't find masternode $i, try again. \n"
        i=""
    fi
done

nano -c /etc/masternodes/${PROJECT}_n${i}.conf

while :; do
    printf "${cyan}"
    echo -e "\n"
    echo -e "\n Changes to that masternode rquire a restart to take effect."
    read -n 1 -s -r -p "  --> Would you like to restart this masternode now? y/n  " VERIFY
    if [[ $VERIFY == "y" || $VERIFY == "Y" ]]
    then printf "${cyan}" ; break
elif [[ $VERIFY == "n" || $VERIFY == "N" ]]
    echo -e "\n"
    echo -e " Changes to your masternode.conf will not take effect until it is restarted\n"
    then exit
    fi
done

echo -e "\n"
echo -e " `date +%m.%d.%Y_%H:%M:%S` : Running mnedit.sh to quickly edit masternode configuration." | tee -a "$LOGFILE"
echo -e  " User has viewed or edited /etc/masternodes/${PROJECT}_n${i}.conf\n"  | tee -a "$LOGFILE"

touch $INSTALLDIR/temp/updating
echo -e " Disabling ${PROJECT}_n${i} now."
sudo systemctl disable ${PROJECT}_n${i}
sudo systemctl stop ${PROJECT}_n${i}
echo -e " Restarting masternode."
sudo systemctl enable ${PROJECT}_n${i}
sudo systemctl start ${PROJECT}_n${i}

# echo -e " Unsetting -update flag \n"
rm -f $INSTALLDIR/temp/updating

# echo -e " Your changes to the masternode are now complete \n"
