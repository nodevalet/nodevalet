#!/bin/bash
# Check if reboot is required, and if so, reboot
# Add the following to the crontab (i.e. crontab -e)
# (crontab -l ; echo "30 */10 * * * $INSTALLDIR/maintenance/rebootq.sh") | crontab -

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

if [ -e $INSTALLDIR/temp/updating ]
then echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Running rebootq.sh" | tee -a "$LOGFILE"
    echo -e " It looks like I'm busy with other tasks; skipping reboot check.\n"  | tee -a "$LOGFILE"
    exit
fi

# delay task (1 hour) if activate_masternodes is running
if [ -e "$INSTALLDIR/temp/activating" ]
then sleep 3600
    rm -rf $INSTALLDIR/temp/activating
fi

# write which packages require it
cat /run/reboot* > $INSTALLDIR/temp/REBOOTREQ

if grep -q "restart required" "$INSTALLDIR/temp/REBOOTREQ"
then echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Checking if system requires a reboot" | tee -a "$LOGFILE"
    echo -e " ${yellow}Server will restart now to install the following update(s):${nocolor}" | tee -a "$LOGFILE"

    # this sed removes the line "*** System restart required ***" from the REBOOTREQ
    sed -i '/restart required/d' $INSTALLDIR/temp/REBOOTREQ

    # this echo writes the packages requiring reboot to the log
    echo -e "${lightred} --> $(cat ${INSTALLDIR}/temp/REBOOTREQ) ${nocolor}\n" | tee -a "$LOGFILE"

    rm $INSTALLDIR/temp/REBOOTREQ
    shutdown -r now "Server is going down for upgrade."
else
    echo -e " No reboot is required at this time\n"
    rm $INSTALLDIR/temp/REBOOTREQ
fi

exit
