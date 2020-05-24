#!/bin/bash
# disable the crons that could cause problems with other scripts

# exit with error if not run as root/sudo
if [ "$(id -u)" != "0" ]
then echo -e "\n Please re-run as root or sudo.\n"
    exit 1
fi

crontab -l | grep -v '/var/tmp/nodevalet/maintenance/rebootq.sh'  | crontab -
crontab -l | grep -v '/var/tmp/nodevalet/maintenance/checkdaemon.sh'  | crontab -
crontab -l | grep -v '/var/tmp/nodevalet/maintenance/autoupdate.sh'  | crontab -
crontab -l | grep -v '/var/tmp/nodevalet/maintenance/cronchecksync1.sh'  | crontab -
crontab -l | grep -v '/var/tmp/nodevalet/maintenance/cleardebuglog.sh'  | crontab -
