#!/bin/bash
# restore maintenance crons that were previously disabled

# exit with error if not run as root/sudo
if [ "$(id -u)" != "0" ]
then echo -e "\n Please re-run as root or sudo.\n"
    exit 1
fi

crontab -r
echo -e "${yellow} Re-enabling crontabs that were previously disabled:${nocolor}"
echo -e "${white}  --> Check for & reboot if needed to install updates every 10 hours${nocolor}"
(crontab -l ; echo "59 */10 * * * /var/tmp/nodevalet/maintenance/rebootq.sh") | crontab -
echo -e "${white}  --> Check for stuck blocks every 30 minutes${nocolor}"
(crontab -l ; echo "1,31 * * * * /var/tmp/nodevalet/maintenance/checkdaemon.sh") | crontab -
echo -e "${white}  --> Check for wallet updates every 48 hours${nocolor}"
(crontab -l ; echo "2 */48 * * * /var/tmp/nodevalet/maintenance/autoupdate.sh") | crontab -
echo -e "${white}  --> Check if chains are syncing or synced every 5 minutes${nocolor}"
(crontab -l ; echo "*/5 * * * * /var/tmp/nodevalet/maintenance/cronchecksync1.sh") | crontab -
echo -e "${white}  --> Clear daemon debug logs weekly to prevent clog${nocolor}"
(crontab -l ; echo "@weekly /var/tmp/nodevalet/maintenance/cleardebuglog.sh") | crontab -
