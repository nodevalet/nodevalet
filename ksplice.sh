#!/bin/bash
# install Ksplice Uptrack

#####################
## Ksplice Install ##
#####################

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

function ksplice_install() {

    # -------> I still need to install an error check after installing Ksplice to make sure \
        #          the install completed before moving on the configuration

    # prompt users on whether to install Oracle ksplice or not
    # install created using https://tinyurl.com/y9klkx2j and https://tinyurl.com/y8fr4duq
    # Official page: https://ksplice.oracle.com/uptrack/guide
    echo -e -n "${lightcyan}"
    # figlet Ksplice Uptrack
    echo -e -n "${yellow}"
    clear
    echo -e "---------------------------------------------- "
    echo -e " $(date +%m.%d.%Y_%H:%M:%S) : INSTALL ORACLE KSPLICE "
    echo -e "---------------------------------------------- \n"
    echo -e -n "${lightcyan}"
    echo -e " Normally, kernel updates in Linux require a system reboot. Ksplice"
    echo -e " Uptrack installs these patches in memory for Ubuntu and Fedora"
    echo -e " Linux so reboots are not needed. It is free for non-commercial use."
    echo -e " To minimize server downtime, this is a good thing to install."

    echo -e -n "${cyan}"
    while :; do
        echo -e "\n"
        read -n 1 -s -r -p " Would you like to install Oracle Ksplice Uptrack now? y/n " KSPLICE
        if [[ ${KSPLICE,,} == "y" || ${KSPLICE,,} == "Y" || ${KSPLICE,,} == "N" || ${KSPLICE,,} == "n" ]]
        then
            break
        fi
    done
    echo -e "${nocolor}"
    echo -e "\n"

    if [ "${KSPLICE,,}" = "Y" ] || [ "${KSPLICE,,}" = "y" ]
    then
        # install ksplice uptrack
        echo -e -n "${yellow}"
        echo -e "--------------------------------------------------- "
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : INSTALLING KSPLICE PACKAGES "
        echo -e "--------------------------------------------------- "
        echo -e -n "${white}"
        echo ' # apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install '
        echo '   libgtk2-perl consolekit iproute libck-connector0 libcroco3 libglade2-0 '
        echo '   libpam-ck-connector librsvg2-2 librsvg2-common python-cairo python-gtk2 '
        echo '   python-dbus python-gi python-glade2 python-gobject-2 python-pycurl '
        echo '   python-yaml dbus-x11 python-six python3-yaml '
        echo -e "--------------------------------------------------- "
        echo -e -n "${nocolor}"
        apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install \
            libgtk2-perl consolekit iproute libck-connector0 libcroco3 libglade2-0 \
            libpam-ck-connector librsvg2-2 librsvg2-common python-cairo python-gtk2 \
            python-dbus python-gi python-glade2 python-gobject-2 python-pycurl \
            python-yaml dbus-x11 python-six python3-yaml
        echo -e -n "${yellow}"
        echo -e "---------------------------------------------------- "
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : KSPLICE PACKAGES INSTALLED"
        echo -e "---------------------------------------------------- "
        echo -e " --> Download & install Ksplice package from Oracle "
        echo -e "---------------------------------------------------- "
        echo -e -n "${nocolor}"
        wget -o /var/log/ksplicew1.log https://ksplice.oracle.com/uptrack/dist/xenial/ksplice-uptrack.deb
        dpkg --log "$LOGFILE" -i ksplice-uptrack.deb
        if [ -e /etc/uptrack/uptrack.conf ]
        then
            echo -e -n "${lightgreen}"
            echo -e "---------------------------------------------------- "
            echo -e " $(date +%m.%d.%Y_%H:%M:%S) : KSPLICE UPTRACK INSTALLED"
            echo -e "---------------------------------------------------- "
            echo -e -n "${yellow}"
            echo -e " ** Enabling autoinstall & correcting permissions ** "
            sed -i "s/autoinstall = no/autoinstall = yes/" /etc/uptrack/uptrack.conf
            chmod 755 /etc/cron.d/uptrack
            echo -e "---------------------------------------------------- "
            echo -e " ** Activate & install Ksplice patches & updates ** "
            echo -e "---------------------------------------------------- "
            echo -e -n "${nocolor}"
            uptrack-upgrade -y
            echo -e -n "${lightgreen}"
            echo -e "------------------------------------------------- "
            echo -e " $(date +%m.%d.%Y_%H:%M:%S) : KSPLICE UPDATES INSTALLED"
            echo -e "------------------------------------------------- \n"
            echo -e -n "${nocolor}"
            sleep 1	; #  dramatic pause
            echo -e -n "${lightgreen}"
            echo -e "------------------------------------------------- "
            echo " $(date +%m.%d.%Y_%H:%M:%S) : SUCCESS : Ksplice Enabled"
            echo -e "------------------------------------------------- \n"
            echo -e -n "${nocolor}"
        else  	echo -e -n "${lightred}"
            echo -e "-------------------------------------------------------- "
            echo " $(date +%m.%d.%Y_%H:%M:%S) : FAIL : Ksplice was not Installed"
            echo -e "-------------------------------------------------------- \n"
            echo -e -n "${nocolor}"
        fi
    else :
        echo -e -n "${yellow}"
        echo -e "---------------------------------------------------- "
        echo -e "     ** User elected not to install Ksplice ** "
        echo -e "---------------------------------------------------- \n"
        echo -e -n "${nocolor}"
    fi
}

ksplice_install