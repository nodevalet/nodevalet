#!/bin/bash
# Stop and disable a particular masternode

INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
PROJECT=$(<$INFODIR/vpscoin.info)
MNS=$(<$INFODIR/vpsnumber.info)
LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
MNODE_DAEMON=$(<$INSTALLDIR/temp/MNODE_DAEMON)
HNAME=$(<$INFODIR/vpshostname.info)

# set mnode daemon name from project.env
MNODE_DAEMON=$(grep ^MNODE_DAEMON $INSTALLDIR/nodemaster/config/"${PROJECT}"/"${PROJECT}".env)
echo -e "$MNODE_DAEMON" > $INSTALLDIR/temp/MNODE_DAEMON
sed -i "s/MNODE_DAEMON=\${MNODE_DAEMON:-\/usr\/local\/bin\///" $INSTALLDIR/temp/MNODE_DAEMON  2>&1
cat $INSTALLDIR/temp/MNODE_DAEMON | tr -d '[}]' > $INSTALLDIR/temp/MNODE_DAEMON1
MNODE_DAEMON=$(<$INSTALLDIR/temp/MNODE_DAEMON1)
cat $INSTALLDIR/temp/MNODE_DAEMON1 > $INSTALLDIR/temp/MNODE_DAEMON ; rm -f $INSTALLDIR/temp/MNODE_DAEMON1

# read first argument to string
i=$1

# if no argument was given, give instructions and ask for one

if [ -z "$i" ]
then clear
    echo -e "\n This scriptlet will stop and disable a particular masternode."
    echo -e " Which masternode would you like to disable? \n"

fi
while :; do
    if [ -z "$i" ] ; then read -p " --> " i ; fi
    [[ $i =~ ^[0-9]+$ ]] || { printf "${lightred}";echo -e "\n --> I only recognize numbers; enter  enter a number between 1 and $MNS...\n"; i=""; continue; }
    if (($i >= 1 && $i <= $MNS)); then break
    else echo -e "\n --> I don't have a masternode $i; enter a number between 1 and $MNS.\n"
        i=""
    fi
done

echo -e "\n"
echo -e "$(date +%m.%d.%Y_%H:%M:%S) : Running mnstop.sh" | tee -a "$LOGFILE"
echo -e " User has asked to disable masternode ${PROJECT}_n${i}.\n"  | tee -a "$LOGFILE"

touch $INSTALLDIR/temp/updating

echo -e " Disabling ${PROJECT}_n${i} now."
sudo systemctl disable "${PROJECT}"_n${i}
sudo systemctl stop "${PROJECT}"_n${i}
sleep 2

# echo -e " Unsetting -update flag \n"
rm -f $INSTALLDIR/temp/updating
