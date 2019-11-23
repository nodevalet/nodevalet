#!/bin/bash
# Check if reboot is required, and if so, reboot
# Add the following to the crontab (i.e. crontab -e)
# (crontab -l ; echo "30 */10 * * * $INSTALLDIR/maintenance/rebootq.sh") | crontab -

INSTALLDIR='/var/tmp/nodevalet'
LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'

### define colors ###
lightred=$'\033[1;31m'  # light red
red=$'\033[0;31m'  # red
lightgreen=$'\033[1;32m'  # light green
green=$'\033[0;32m'  # green
lightblue=$'\033[1;34m'  # light blue
blue=$'\033[0;34m'  # blue
lightpurple=$'\033[1;35m'  # light purple
purple=$'\033[0;35m'  # purple
lightcyan=$'\033[1;36m'  # light cyan
cyan=$'\033[0;36m'  # cyan
lightgray=$'\033[0;37m'  # light gray
white=$'\033[1;37m'  # white
brown=$'\033[0;33m'  # brown
yellow=$'\033[1;33m'  # yellow
darkgray=$'\033[1;30m'  # dark gray
black=$'\033[0;30m'  # black
nocolor=$'\e[0m' # no color

if [ -e $INSTALLDIR/temp/updating ]
then echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Running rebootq.sh" | tee -a "$LOGFILE"
    echo -e " It looks like I'm busy with other tasks; skipping reboot check.\n"  | tee -a "$LOGFILE"
    exit
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
    sudo reboot

else
    echo -e " No reboot is required at this time\n"
    rm $INSTALLDIR/temp/REBOOTREQ
fi

exit
