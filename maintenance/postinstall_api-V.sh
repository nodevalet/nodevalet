#!/bin/bash

function final_message() {

if [ -e /root/vpsvaletreboot.txt ]; then
	# Set Variables
	INSTALLDIR='/root/installtemp'
	LOGFILE='/root/installtemp/silentinstall.log'
	TRANSMITMN=`cat /root/installtemp/masternode.return`

	# set hostname variable to the name planted by install script
	if [ -e $INSTALLDIR/vpshostname.info ]
	then HNAME=$(<$INSTALLDIR/vpshostname.info)
	else HNAME=`hostname`
	fi

	# log successful reboot
	echo -e "Server has restarted after masternode install"  | tee -a "$LOGFILE"
	echo -e "Sending masternode.return data to mothership"  | tee -a "$LOGFILE"
	# transmit masternode.return to mothership
	curl -X POST https://www.heliumstats.online/code-red/status.php -H 'Content-Type: application/json-rpc' -d '{"hostname":"'"$HNAME"'","message": "'"$TRANSMITMN"'"}'

# Add a sequence to interpret the reply as success or fail $?
rm /root/vpsvaletreboot.txt

# add code to clean up the rest of unnecessary files; keep the log and masternode files except for the mnaddresses
# rm -rf /root/installtemp

else :
fi
}

final_message
# automatically check for wallet updates every 1 day
	echo -e "Adding crontab to check for wallet updates every day"  | tee -a "$LOGFILE"	
	(crontab -l ; echo "* * 1 * * /root/code-red/autoupdate/autoupdate.sh") | crontab -   | tee -a "$LOGFILE"
# automatically check that for stuck blocks and restart masternode if it is stuck
	echo -e "Adding crontab to check for stuck blocks every 30 minutes"  | tee -a "$LOGFILE"
	(crontab -l ; echo "*/30 * * * * /root/code-red/maintenance/checkdaemon.sh") | crontab -   | tee -a "$LOGFILE"
	
exit
