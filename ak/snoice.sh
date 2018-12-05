#!/bin/bash
# For testing things and figuring out how they work
#
clear

function setup_environment() {
### add colors ###
lightred='\033[1;31m'  # light red
red='\033[0;31m'  # red
lightgreen='\033[1;32m'  # light green
green='\033[0;32m'  # green
lightblue='\033[1;34m'  # light blue
blue='\033[0;34m'  # blue
lightpurple='\033[1;35m'  # light purple
purple='\033[0;35m'  # purple
lightcyan='\033[1;36m'  # light cyan
cyan='\033[0;36m'  # cyan
lightgray='\033[0;37m'  # light gray
white='\033[1;37m'  # white
brown='\033[0;33m'  # brown
yellow='\033[1;33m'  # yellow
darkgray='\033[1;30m'  # dark gray
black='\033[0;30m'  # black
nocolor='\033[0m'    # no color

printf "..%s.." "${lightred}"
printf "..%s.." "${lightgreen}"
printf "..%s.." "${nocolor}"

# Set Vars
LOGFILE='/var/log/logjammin.log'
}

function begin_log() {
# Create Log File and Begin
printf "..%s.." "${lightcyan}"
rm -rf $LOGFILE
echo -e "---------------------------------------------------- " | tee -a "$LOGFILE"
echo -e " `date +%m.%d.%Y_%H:%M:%S` : SCRIPT STARTED SUCCESSFULLY " | tee -a "$LOGFILE"
echo -e "---------------------------------------------------- " | tee -a "$LOGFILE"
echo -e "---------- AKcryptoGUY's Testing Script ------------ " | tee -a "$LOGFILE"
echo -e "---------------------------------------------------- \n" | tee -a "$LOGFILE"
printf "..%s.." "${nocolor}"
sleep 1
}

setup_environment
begin_log

# install packages over IP4
apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install figlet shellcheck
