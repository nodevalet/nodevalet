#!/bin/bash
# This script will display the NodeValet maintenance log for your VPS

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

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
echo -e " # This script will now display the NodeValet maintenance log  #"
echo -e " # which is stored at /var/tmp/nodevalet/logs/maintenance.log  #"
echo -e " ###############################################################\n"

cat $LOGFILE
echo -e "\n"
