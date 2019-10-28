#!/bin/bash
# Check if reboot is required, and if so, reboot
# Add the following to the crontab (i.e. crontab -e)
# (crontab -l ; echo "30 */10 * * * $INSTALLDIR/maintenance/rebootq.sh") | crontab -

INSTALLDIR='/var/tmp/nodevalet'
LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'

if [ -e $INSTALLDIR/temp/updating ]
then echo -e "$(date +%m.%d.%Y_%H:%M:%S) : Running rebootq.sh" | tee -a "$LOGFILE"
    echo -e " It looks like I'm busy with other tasks; skipping reboot check.\n"  | tee -a "$LOGFILE"
    exit
fi

# write which packages require it
cat /run/reboot* > $INSTALLDIR/temp/REBOOTREQ

if grep -q "restart required" "$INSTALLDIR/temp/REBOOTREQ"
then echo -e "$(date +%m.%d.%Y_%H:%M:%S) : Checking if system requires a reboot" | tee -a "$LOGFILE"
    echo -e " The following packages require a reboot to install updates:" | tee -a "$LOGFILE"

    # this sed removes the line "*** System restart required ***" from the REBOOTREQ
    sed -i '/restart required/d' $INSTALLDIR/temp/REBOOTREQ

    # this echo writes the packages requiring reboot to the log
    echo -e "$(cat ${INSTALLDIR}/temp/REBOOTREQ)" | tee -a "$LOGFILE"

    rm $INSTALLDIR/temp/REBOOTREQ
    echo -e " Server will reboot immediately to complete required updates \n" | tee -a "$LOGFILE"
    # shutdown -r +5 " Server will restart in 5 minutes to complete required updates"
    sudo reboot

else
    echo -e " No reboot is required at this time\n"
    rm $INSTALLDIR/temp/REBOOTREQ
fi

exit
