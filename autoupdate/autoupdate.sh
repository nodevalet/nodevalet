#!/bin/bash
# to be added to crontab to run updatebinaries and, if that fails, run updatefromsource, if that fails, restarts daemon and try again tomorrow.

LOGFILE='/var/temp/nodevalet/log/autoupdate.log'
INSTALLDIR='/var/temp/nodevalet'
PROJECT=`cat $INSTALLDIR/info/vpscoin.info`

echo -e "`date +%m.%d.%Y_%H:%M:%S` : Autoupdate is looking for new $PROJECT tags." | tee -a "$LOGFILE"

bash $INSTALLDIR/autoupdate/updatebinaries.sh || bash $INSTALLDIR/autoupdate/updatefromsource.sh || rm -f $INSTALLDIR/updating | /usr/local/bin/activate_masternodes_"$PROJECT"
