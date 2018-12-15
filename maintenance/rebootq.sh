#!/bin/bash
# Check if reboot is required, and if so, reboot
# Add the following to the crontab (i.e. crontab -e)
# */30 * * * * /root/code-red/maintenance/rebootq.sh

INSTALLDIR='/root/installtemp'
LOGFILE='/root/installtemp/update-reboot.log'

# if reqboot is required, write which packages require it
cat /run/reboot* > $INSTALLDIR/REBOOTREQ

if [ -s $INSTALLDIR/REBOOTREQ ]
then echo -e "`date +%m.%d.%Y_%H:%M:%S` : Reboot required to finish installing these updates" | tee -a "$LOGFILE"
echo -e "`cat /run/reboot*" | tee -a "$LOGFILE"
rm $INSTALLDIR/REBOOTREQ
shutdown -r +5 "Restarting server to install updates"
# reboot server
	
else 
echo -e "No restart is required at this time"
fi

exit
