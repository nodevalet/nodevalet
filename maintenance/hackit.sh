#!/bin/bash
# This script will automatically update scripts on NodeValet VPS
# systems and install some new tools intended only for power users

INSTALLDIR='/var/tmp/nodevalet/maintenance'
INFODIR='/var/tmp/nvtemp'
PROJECT=$(cat $INFODIR/vpscoin.info)
LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'

if [ -e $INSTALLDIR/temp/updating ]
then echo -e "$(date +%m.%d.%Y_%H:%M:%S) : Running hackit.sh" | tee -a "$LOGFILE"
    echo -e " It looks like I'm busy with something else; stopping update.\n"  | tee -a "$LOGFILE"
    exit
fi

# verify that this is a NodeValet.io configured VPS
if [ -z "$PROJECT" ]
then clear
    echo -e "\n This is not a VPS that was configured by NodeValet and"
    echo -e " as a result, these scripts would do nothing for you. \n"
    echo -e "\n The installation will now terminate.\n"
    exit
else cd $INSTALLDIR

    clear
    echo -e "\n This script will now update NodeValet maintenance scripts "
    echo -e " and install some new tools intended for power users only."
    echo -e " These scripts are not supported or endorsed by NodeValet"
    echo -e " and you install them at your own risk. \n"

    # install additional powertools
    echo -e " Downloading and installing hackit.sh"
    sudo wget -q -N https://raw.githubusercontent.com/akcryptoguy/nodevalet.hacks/master/hackit.sh
    sudo ln -nsf $INSTALLDIR/hackit.sh /usr/local/bin/hackit 2>/dev/null
    echo -e " Downloading and installing mnedit.sh"
    sudo wget -q -N https://raw.githubusercontent.com/akcryptoguy/nodevalet.hacks/master/mnedit.sh
    sudo ln -nsf $INSTALLDIR/mnedit.sh /usr/local/bin/mnedit 2>/dev/null
    echo -e " Downloading and installing maxconnections.sh"
    sudo wget -q -N https://raw.githubusercontent.com/akcryptoguy/nodevalet.hacks/master/maxconnections.sh
    sudo ln -nsf $INSTALLDIR/maxconnections.sh /usr/local/bin/maxconnections 2>/dev/null
    echo -e " Downloading and installing mlogedit.sh"
    sudo wget -q -N https://raw.githubusercontent.com/akcryptoguy/nodevalet.hacks/master/mlogedit.sh
    sudo ln -nsf $INSTALLDIR/mlogedit.sh /usr/local/bin/mlogedit 2>/dev/null
    echo -e " Downloading and installing swapedit.sh"
    sudo wget -q -N https://raw.githubusercontent.com/akcryptoguy/nodevalet.hacks/master/swapedit.sh
    sudo ln -nsf $INSTALLDIR/swapedit.sh /usr/local/bin/swapedit 2>/dev/null

    # download the latest version of NodeValet maintenance scripts
    echo -e " Downloading and installing showlog.sh"
    sudo wget -q -N https://raw.githubusercontent.com/nodevalet/nodevalet/master/maintenance/showlog.sh
    sudo ln -nsf $INSTALLDIR/showlog.sh /usr/local/bin/showlog 2>/dev/null
    echo -e " Downloading and installing showmlog.sh"
    sudo wget -q -N https://raw.githubusercontent.com/nodevalet/nodevalet/master/maintenance/showmlog.sh
    sudo ln -nsf $INSTALLDIR/showmlog.sh /usr/local/bin/showmlog 2>/dev/null
    echo -e " Downloading and installing clonesync.sh"
    sudo wget -q -N https://raw.githubusercontent.com/nodevalet/nodevalet/master/maintenance/clonesync.sh
    sudo ln -nsf $INSTALLDIR/clonesync.sh /usr/local/bin/clonesync 2>/dev/null
    echo -e " Downloading and installing clonesync_all.sh"
    sudo wget -q -N https://raw.githubusercontent.com/nodevalet/nodevalet/master/maintenance/clonesync_all.sh
    sudo ln -nsf $INSTALLDIR/clonesync_all.sh /usr/local/bin/clonesync_all 2>/dev/null
    echo -e " Downloading and installing mnstop.sh"
    sudo wget -q -N https://raw.githubusercontent.com/nodevalet/nodevalet/master/maintenance/mnstop.sh
    sudo ln -nsf $INSTALLDIR/mnstop.sh /usr/local/bin/mnstop 2>/dev/null
    echo -e " Downloading and installing mnstart.sh"
    sudo wget -q -N https://raw.githubusercontent.com/nodevalet/nodevalet/master/maintenance/mnstart.sh
    sudo ln -nsf $INSTALLDIR/mnstart.sh /usr/local/bin/mnstart 2>/dev/null
    echo -e " Downloading and installing mulligan.sh"
    sudo wget -q -N https://raw.githubusercontent.com/nodevalet/nodevalet/master/maintenance/mulligan.sh
    sudo ln -nsf $INSTALLDIR/mulligan.sh /usr/local/bin/mulligan 2>/dev/null

    echo -e " Downloading and installing cronchecksync1.sh"
    sudo wget -q -N https://raw.githubusercontent.com/nodevalet/nodevalet/master/maintenance/cronchecksync1.sh
    echo -e " Downloading and installing cronchecksync2.sh"
    sudo wget -q -N https://raw.githubusercontent.com/nodevalet/nodevalet/master/maintenance/cronchecksync2.sh

    echo -e " Updating autoupdate.sh"
    sudo wget -q -N https://raw.githubusercontent.com/nodevalet/nodevalet/master/maintenance/autoupdate.sh
    echo -e " Updating checkdaemon.sh"
    sudo wget -q -N https://raw.githubusercontent.com/nodevalet/nodevalet/master/maintenance/checkdaemon.sh
    echo -e " Updating checksync.sh"
    sudo wget -q -N https://raw.githubusercontent.com/nodevalet/nodevalet/master/maintenance/checksync.sh
    echo -e " Updating cleardebuglog.sh"
    sudo wget -q -N https://raw.githubusercontent.com/nodevalet/nodevalet/master/maintenance/cleardebuglog.sh
    echo -e " Updating getinfo.sh"
    sudo wget -q -N https://raw.githubusercontent.com/nodevalet/nodevalet/master/maintenance/getinfo.sh
    echo -e " Updating killswitch.sh"
    sudo wget -q -N https://raw.githubusercontent.com/nodevalet/nodevalet/master/maintenance/killswitch.sh
    echo -e " Updating makerun.sh"
    sudo wget -q -N https://raw.githubusercontent.com/nodevalet/nodevalet/master/maintenance/makerun.sh
    echo -e " Updating masternodestatus.sh"
    sudo wget -q -N https://raw.githubusercontent.com/nodevalet/nodevalet/master/maintenance/masternodestatus.sh
    echo -e " Updating rebootq.sh"
    sudo wget -q -N https://raw.githubusercontent.com/nodevalet/nodevalet/master/maintenance/rebootq.sh
    echo -e " Updating resync.sh"
    sudo wget -q -N https://raw.githubusercontent.com/nodevalet/nodevalet/master/maintenance/resync.sh
    echo -e " Updating bootstrap.sh"
    sudo wget -q -N https://raw.githubusercontent.com/nodevalet/nodevalet/master/maintenance/bootstrap.sh

    # fix permissions, make scripts executable
    chmod 0700 *.sh

    # add or update crontabs (first remove, then add to avoid duplicates)
    echo -e " Adding cronchecksync1.sh crontab \n"
    crontab -l | grep -v '/var/tmp/nodevalet/maintenance/cronchecksync1.sh'  | crontab -
    (crontab -l ; echo "*/5 * * * * /var/tmp/nodevalet/maintenance/cronchecksync1.sh") | crontab -

    echo -e "\n With great power, comes great responsibility. Please be careful"
    echo -e " and don't break your server. These should not be used haphazardly.\n"
    echo -e " $(date +%m.%d.%Y_%H:%M:%S) : User has run hackit.sh from nodevalet.hacks." >> "$LOGFILE"
    echo -e " This updated NodeValet maintenance scripts and installed new power tools\n" >> "$LOGFILE"
fi

exit
