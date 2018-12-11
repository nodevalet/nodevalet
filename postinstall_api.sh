#!/bin/bash

# Set Variables
INSTALLDIR='/root/installtemp'
LOGFILE='/root/installtemp/silentinstall.log'

echo -e "Server has restarted after masternode install"  | tee -a "$LOGFILE"
    
# set hostname variable to the name planted by install script
	if [ -e $INSTALLDIR/vpshostname.info ]
	then HNAME=$(<$INSTALLDIR/vpshostname.info)
	echo -e "vpshostname.info found, setting HNAME to $HNAME"  | tee -a "$LOGFILE"
	else HNAME=`hostname`
	echo -e "vpshostname.info not found, setting HNAME to $HNAME"  | tee -a "$LOGFILE"
fi

if [ -e /root/vpsvaletreboot.txt ]; then
	echo -e "Reporting Reboot complete to mothership"  | tee -a "$LOGFILE"
	curl -X POST https://www.heliumstats.online/code-red/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message":"Masternode deployment complete"}'
	rm /root/vpsvaletreboot.txt
	#rm -rf /root/installtemp
fi
