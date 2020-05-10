#!/bin/bash
# disable the crons that could cause problems with other scripts

crontab -l | grep -v '/var/tmp/nodevalet/maintenance/rebootq.sh'  | crontab -
# crontab -l | grep -v '/var/tmp/nodevalet/maintenance/makerun.sh'  | crontab -
crontab -l | grep -v '/var/tmp/nodevalet/maintenance/checkdaemon.sh'  | crontab -
crontab -l | grep -v '/var/tmp/nodevalet/maintenance/autoupdate.sh'  | crontab -
crontab -l | grep -v '/var/tmp/nodevalet/maintenance/cronchecksync1.sh'  | crontab -
crontab -l | grep -v '/var/tmp/nodevalet/maintenance/cleardebuglog.sh'  | crontab -


