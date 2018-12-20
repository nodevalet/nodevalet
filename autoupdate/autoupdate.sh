#!/bin/bash
# to be added to crontab to run updatebinaries and, if that fails, run updatefromsource, if that fails, restarts daemon and try again tomorrow.

LOGFILE='/var/tmp/nodevalet/logs/autoupdate.log'
INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
PROJECT=`cat $INFODIR/vpscoin.info`

echo -e "`date +%m.%d.%Y_%H:%M:%S` : Autoupdate is looking for new $PROJECT tags." | tee -a "$LOGFILE"

bash $INSTALLDIR/autoupdate/updatebinaries.sh || bash $INSTALLDIR/autoupdate/updatefromsource.sh || rm -f $INSTALLDIR/temp/updating | /usr/local/bin/activate_masternodes_"$PROJECT"
