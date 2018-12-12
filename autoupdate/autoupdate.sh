#!/bin/bash
# to be added to crontab to run updatebinaries and, if that fails, run updatefromsource, if that fails, restarts daemon and try again tomorrow.

bash updatebinaries.sh || bash updatefromsource.sh || cd /usr/local/bin && ./activate_masternodes_helium
