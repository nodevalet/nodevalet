#!/bin/bash
# Check if reboot is required, and if so, reboot
# Add the following to the crontab (i.e. crontab -e)
# */30 * * * * /root/code-red/maintenance/rebootq.sh

INSTALLDIR='/root/installtemp'
LOGFILE='/root/installtemp/rebootq.log'

# if reqboot is required, write which packages require it
cat /run/reboot* > $INSTALLDIR/REBOOTREQ

if [ -s $INSTALLDIR/REBOOTREQ ]; then
	# reboot server
	
then 
else 
fi
	

rm /root/installtemp/rebootq

exit
