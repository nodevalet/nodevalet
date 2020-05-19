#!/bin/bash
# This script will display the NodeValet installation log for your VPS

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

LOGFILE='/var/tmp/nodevalet/logs/silentinstall.log'

# verify that this is a NodeValet.io configured VPS
if [ -z $PROJECT ]
then clear
    echo -e "\n This is not a VPS that was configured by NodeValet and"
    echo -e " as a result, there is no installation log to display. \n"
    echo -e "\n Did you expect something different? Let us know.\n"
    exit 1
else cd $INSTALLDIR
fi

clear
echo -e "\n ################################################################"
echo -e " # This script will now display the NodeValet2 installation log #"
echo -e " # which is stored at /var/tmp/nodevalet/logs/silentinstall.log #"

cat $LOGFILE
echo -e "\n"
