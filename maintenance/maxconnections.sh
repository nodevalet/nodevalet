#!/bin/bash
# This script will let users quickly change the 'maxconnections' of all installed masternodes

LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
MNS=$(<$INFODIR/vpsnumber.info)
PROJECT=$(<$INFODIR/vpscoin.info)
PROJECTl=${PROJECT,,}
PROJECTt=${PROJECTl~}
MNODE_DAEMON=$(<$INFODIR/vpsmnode_daemon.info)
HNAME=$(<$INFODIR/vpshostname.info)

# read first argument to string $NEWMAX
NEWMAX=$1

# if NEWMAX(value only)=0 give instructions and echo them
if [ -z $NEWMAX ]
then clear
    echo -e "\n Your masternodes need to connect to other masternodes in"
    echo -e " order to function properly. Please enter a number of max"
    echo -e " connections you'd like to set (between 25 and 255)  : \n"
fi

while :; do
    if [ -z $NEWMAX ] ; then read -p "  --> " NEWMAX ; fi
    [[ $NEWMAX =~ ^[0-9]+$ ]] || { printf "${lightred}";echo -e " --> Try harder, that's not even a number."; NEWMAX=""; continue; }
    if (($NEWMAX >= 20 && $NEWMAX <= 256)); then break
    else echo -e "\n --> That number is too high or too low, try again. \n"
        NEWMAX=""
    fi
done

echo -e " `date +%m.%d.%Y_%H:%M:%S` : User has run maxconnections.sh from nodevalet.hacks" >> "$LOGFILE"
echo -e " User has manually set all masternode maxconnections to $NEWMAX \n" >> "$LOGFILE"

# set mnode daemon name from project.env
MNODE_DAEMON=`grep ^MNODE_DAEMON $INSTALLDIR/nodemaster/config/${PROJECT}/${PROJECT}.env`
echo -e "$MNODE_DAEMON" > $INSTALLDIR/temp/MNODE_DAEMON
sed -i "s/MNODE_DAEMON=\${MNODE_DAEMON:-\/usr\/local\/bin\///" $INSTALLDIR/temp/MNODE_DAEMON  2>&1
cat $INSTALLDIR/temp/MNODE_DAEMON | tr -d '[}]' > $INSTALLDIR/temp/MNODE_DAEMON1
MNODE_DAEMON=$(<$INSTALLDIR/temp/MNODE_DAEMON1)
cat $INSTALLDIR/temp/MNODE_DAEMON1 > $INSTALLDIR/temp/MNODE_DAEMON ; rm -f $INSTALLDIR/temp/MNODE_DAEMON1

touch $INSTALLDIR/temp/updating
for ((i=1;i<=$MNS;i++));
do

    echo -e "\n `date +%m.%d.%Y_%H:%M:%S` : Setting maxconnections=$NEWMAX in masternode ${PROJECT}_n${i}"
    sed -i "s/^maxconnections=.*/maxconnections=$NEWMAX/" /etc/masternodes/${PROJECT}_n$i.conf

    echo -e " Disabling ${PROJECT}_n${i} now."
    sudo systemctl disable ${PROJECT}_n${i} > /dev/null 2>&1
    sudo systemctl stop ${PROJECT}_n${i}
    echo -e " Restarting masternode."
    sudo systemctl enable ${PROJECT}_n${i} > /dev/null 2>&1
    sudo systemctl start ${PROJECT}_n${i}
    echo -e " Pausing for 5 seconds before continuing to reduce strain on CPU."
    sleep 5

done
# echo -e " Unsetting -update flag \n"
rm -f $INSTALLDIR/temp/updating

echo -e "\n"
echo -e " User has manually set all masternode maxconnections to $NEWMAX \n"
