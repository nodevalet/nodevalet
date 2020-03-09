#!/bin/bash
# This script will display the NodeValet masternode.conf for your VPS

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

# verify that this is a NodeValet.io configured VPS
if [ -z $PROJECT ]
then clear
    echo -e "\n This is not a VPS that was configured by NodeValet and"
    echo -e " as a result, there is no masternode.conf to display. \n"
    echo -e "\n Did you expect something different? Let us know.\n"
    exit
else cd $INSTALLDIR
fi

clear
echo -e "\n"
cat $INSTALLDIR/masternode.conf
echo -e "\n"
