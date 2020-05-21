#!/bin/bash
# load common variables used by NodeValet scripts

# exit with error if not run as root/sudo
if [ "$(id -u)" != "0" ]
then echo -e "\n Please re-run as root or sudo.\n"
    exit 1
fi

### load variables ###
LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
MNS=$(<$INFODIR/vps.number.info)
PROJECT=$(<$INFODIR/vps.coin.info)
PROJECTl=${PROJECT,,}
PROJECTt=${PROJECTl~}
MNODE_DAEMON=$(<$INFODIR/vps.mnode_daemon.info)
MNODE_BINARIES=$(<$INFODIR/vps.binaries.info)
HNAME=$(<$INFODIR/vps.hostname.info)
VPSAPI=$(<$INFODIR/vps.api.info)
ONLYNET=$(<$INFODIR/vps.onlynet.info)
BLOCKEXP=$(<$INFODIR/vps.BLOCKEXP.info)

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
