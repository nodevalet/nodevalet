#!/bin/bash

function final_message() {

if [ -e /root/vpsvaletreboot.txt ]; then
	# Set Variables
	INSTALLDIR='/var/temp/nodevalet'
	LOGFILE='/var/temp/nodevalet/log/silentinstall.log'
	TRANSMITMN=`cat $INSTALLDIR/temp/masternode.return`

	# set hostname variable to the name planted by install script
	if [ -e $INSTALLDIR/info/vpshostname.info ]
	then HNAME=$(<$INSTALLDIR/info/vpshostname.info)
	else HNAME=`hostname`
	fi

	# log successful reboot
	echo -e "Server has restarted after masternode install"  | tee -a "$LOGFILE"
	echo -e "Sending masternode.return data to mother"  | tee -a "$LOGFILE"
	# transmit masternode.return to mother
	curl -X POST https://www.nodevalet.io/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "'"$TRANSMITMN"'"}' ; echo " "
	

# Add a sequence to interpret the reply as success or fail $?
rm /root/vpsvaletreboot.txt
crontab -l | grep -v '$INSTALLDIR/maintenance/postinstall_api.sh'  | crontab -

else :
fi
}

final_message

exit
