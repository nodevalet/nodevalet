#!/bin/bash
# to be added to crontab to run updatebinaries and, if that fails, run updatefromsource, if that fails, restarts daemon and try again tomorrow.

LOGFILE='/root/installtemp/autoupdate.log'

echo -e "Running autoupdate against installed wallet binaries." | tee -a "$LOGFILE"
date | tee -a "$LOGFILE"

bash /root/code-red/autoupdate/updatebinaries.sh || bash /root/code-red/autoupdate/updatefromsource.sh || cd /usr/local/bin && ./activate_masternodes_helium
