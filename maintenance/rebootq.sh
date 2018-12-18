#!/bin/bash
# Check if reboot is required, and if so, reboot
# Add the following to the crontab (i.e. crontab -e)
# (crontab -l ; echo "0 0 12 * * ? /root/code-red/maintenance/rebootq.sh") | crontab - 

INSTALLDIR='/root/installtemp'
LOGFILE='/root/installtemp/update-reboot.log'

if [ -e "$INSTALLDIR/updating ]
	then echo "Looks like I'm installing updates, I'll try again later."  | tee -a "$LOGFILE"
	exit
fi

echo -e "`date +%m.%d.%Y_%H:%M:%S` : Checking if system requires a reboot" | tee -a "$LOGFILE"

# write which packages require it
cat /run/reboot* > $INSTALLDIR/REBOOTREQ

if grep -q "restart required" "$INSTALLDIR/REBOOTREQ"
then echo -e "`date +%m.%d.%Y_%H:%M:%S` : These updates require a reboot:" | tee -a "$LOGFILE"

# this sed removes the line "*** System restart required ***" from the REBOOTREQ
sed -i '/restart required/d' $INSTALLDIR/REBOOTREQ

# this echo writes the packages requiring reboot to the log
echo -e "`cat ${INSTALLDIR}/REBOOTREQ`" | tee -a "$LOGFILE"

rm $INSTALLDIR/REBOOTREQ
echo -e "Server will restart in 5 minutes to complete required updates \n" | tee -a "$LOGFILE"
shutdown -r +5 "Server will restart in 5 minutes to complete required updates"

else
echo -e "No reboot is required at this time\n" | tee -a "$LOGFILE"
rm $INSTALLDIR/REBOOTREQ
fi

exit
