#!/bin/bash
# to be added to crontab to run updatebinaries and, if that fails, run updatefromsource, if that fails, restarts daemon and try again tomorrow.

LOGFILE='/root/installtemp/autoupdate.log'

echo -e "`date +%m.%d.%Y_%H:%M:%S` : Running autoupdate to make sure wallet software is up to date." | tee -a "$LOGFILE"

INSTALLDIR='/root/installtemp'
PROJECT=`cat $INSTALLDIR/vpscoin.info`
bash /root/code-red/autoupdate/updatebinaries.sh || bash /root/code-red/autoupdate/updatefromsource.sh || cd /usr/local/bin && ./activate_masternodes_"$PROJECT"
