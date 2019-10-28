#!/bin/bash
# This script will display the NodeValet maintenance log for your VPS

INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
PROJECT=$(<$INFODIR/vpscoin.info)
MNS=$(<$INFODIR/vpsnumber.info)
LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
MNODE_DAEMON=$(<$INSTALLDIR/temp/MNODE_DAEMON)
HNAME=$(<$INFODIR/vpshostname.info)

# verify that this is a NodeValet.io configured VPS
if [ -z $PROJECT ]
then clear
    echo -e "\n This is not a VPS that was configured by NodeValet and"
    echo -e " as a result, there is no maintenance log to display. \n"
    echo -e "\n Did you expect something different? Let us know.\n"
    exit
else cd $INSTALLDIR
fi

clear
echo -e "\n ###############################################################"
echo -e " # This script will now display the NodeValet installation log #"
echo -e " # which is stored at /var/tmp/nodevalet/logs/maintenance.log  #"
echo -e " ###############################################################\n"

cat $LOGFILE
echo -e "\n"
