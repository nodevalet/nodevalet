#!/bin/bash

# Set Variables
INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
PROJECT=`cat $INFODIR/vpscoin.info`
LOGFILE='/var/tmp/nodevalet/logs/silentinstall.log'
TRANSMITMN=`cat $INSTALLDIR/temp/masternode.return`


function final_message() {

if [ -e $INSTALLDIR/temp/vpsvaletreboot.txt ]; then

	# set hostname variable to the name planted by install script
	if [ -e $INFODIR/vpshostname.info ]
	then HNAME=$(<$INFODIR/vpshostname.info)
	else HNAME=`hostname`
	fi

	# log successful reboot
	echo -e "Server has restarted after masternode install"  | tee -a "$LOGFILE"
	echo -e "Sending masternode.return data to mother"  | tee -a "$LOGFILE"
	# transmit masternode.return to mother
	curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "'"$TRANSMITMN"'"}' ; echo " "
	

# Add a sequence to interpret the reply as success or fail $?
rm $INSTALLDIR/temp/vpsvaletreboot.txt
crontab -l | grep -v '$INSTALLDIR/maintenance/postinstall_api.sh'  | crontab -

else :
fi
}

final_message

exit
