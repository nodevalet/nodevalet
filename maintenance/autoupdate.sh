#!/bin/bash
# to be added to crontab to updatebinaries using any means necessary

# exit with error if not run as root/sudo
if [ "$(id -u)" != "0" ]
then echo -e "\n Please re-run as root or sudo.\n"
    exit 1
fi

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

if [ -e "$INSTALLDIR/temp/shuttingdown" ]
then echo -e " Skipping autoupdate.sh because the server is shutting down.\n" | tee -a "$LOGFILE"
    exit
fi

# delay task for 1 hour if activate_masternodes is running
if [ -e "$INSTALLDIR/temp/activating" ]
then sleep 3600
    rm -f $INSTALLDIR/temp/activating
fi

# update .gitstring binary search string variable and .env
cd $INSTALLDIR/nodemaster/config/$PROJECT
echo -e "\n $(date +%m.%d.%Y_%H:%M:%S) : Downloading current $PROJECT.gitstring & .env"
curl -LJO https://raw.githubusercontent.com/nodevalet/nodevalet/master/nodemaster/config/$PROJECT/$PROJECT.gitstring
curl -LJO https://raw.githubusercontent.com/nodevalet/nodevalet/master/nodemaster/config/$PROJECT/$PROJECT.env

# set mnode daemon name from project.env
MNODE_DAEMON=$(grep ^MNODE_DAEMON $INSTALLDIR/nodemaster/config/"${PROJECT}"/"${PROJECT}".env)
echo -e "$MNODE_DAEMON" > $INSTALLDIR/temp/MNODE_DAEMON
sed -i "s/MNODE_DAEMON=\${MNODE_DAEMON:-\/usr\/local\/bin\///" $INSTALLDIR/temp/MNODE_DAEMON  2>&1
cat $INSTALLDIR/temp/MNODE_DAEMON | tr -d '[}]' > $INSTALLDIR/temp/MNODE_DAEMON1
MNODE_DAEMON=$(<$INSTALLDIR/temp/MNODE_DAEMON1)
cat $INSTALLDIR/temp/MNODE_DAEMON1 > $INFODIR/vps.mnode_daemon.info
rm $INSTALLDIR/temp/MNODE_DAEMON1 ; rm $INSTALLDIR/temp/MNODE_DAEMON
echo -e "${MNODE_DAEMON::-1}" > $INFODIR/vps.binaries.info 2>&1
MNODE_BINARIES=$(<$INFODIR/vps.binaries.info)

# Pull GITAPI_URL from $PROJECT.env
GIT_API=$(grep ^GITAPI_URL $INSTALLDIR/nodemaster/config/${PROJECT}/${PROJECT}.env)
echo "$GIT_API" > $INFODIR/vps.GIT_API.info
sed -i "s/GITAPI_URL=//" $INFODIR/vps.GIT_API.info
GITAPI_URL=$(<$INFODIR/vps.GIT_API.info)

# Pull GIT URL from $PROJECT.env
GIT_URL=$(grep ^GIT_URL $INSTALLDIR/nodemaster/config/${PROJECT}/${PROJECT}.env)
echo "$GIT_URL" > $INFODIR/vps.GIT_URL.info
sed -i "s/GIT_URL=//" $INFODIR/vps.GIT_URL.info
GIT_URL=$(<$INFODIR/vps.GIT_URL.info)

# Pull GITSTRING from $PROJECT.env
GITSTRING=$(cat $INSTALLDIR/nodemaster/config/${PROJECT}/${PROJECT}.gitstring)

if [ -e $INSTALLDIR/temp/updating ]
then echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Autoupdate.sh detected update flag, wait 30 min" | tee -a "$LOGFILE"
    echo -e " Removing maintenance flag that was leftover from previous activity.\n"  | tee -a "$LOGFILE"
    sleep 1800
    rm -f $INSTALLDIR/temp/updating
fi

function remove_cron_function() {
    # disable the crons that could cause problems
    . /var/tmp/nodevalet/maintenance/remove_crons.sh
}

function restore_cron_function() {
    # restore maintenance crons that were previously disabled
    . /var/tmp/nodevalet/maintenance/restore_crons.sh
}

function update_binaries() {
    echo -e "\n $(date +%m.%d.%Y_%H:%M:%S) : Autoupdate is looking for new $PROJECTt tags"

    if [ ! -d $INSTALLDIR/temp/bin ]; then mkdir $INSTALLDIR/temp/bin ; fi
    cd $INSTALLDIR/temp/bin
    rm -r -f $PROJECT*
    CURVERSION=$(cat $INSTALLDIR/temp/currentversion)
    NEWVERSION="$(curl -s $GITAPI_URL | grep tag_name)"
    # if versions not equal AND current version is not empty
    if [ "$CURVERSION" != "$NEWVERSION" ] && [ ${#NEWVERSION} != 0 ]
    then echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Autoupdate detected new $PROJECTt tags" | tee -a "$LOGFILE"
        echo -e " Installed version is : $CURVERSION" | tee -a "$LOGFILE"
        echo -e " New version detected : $NEWVERSION" | tee -a "$LOGFILE"
        echo -e "${lightcyan} ** Attempting to install new $PROJECTt binaries ** ${nocolor}\n" | tee -a "$LOGFILE"
        touch $INSTALLDIR/temp/updating
        systemctl stop $PROJECT*
        if [ ! -d /usr/local/bin/backup ]; then mkdir /usr/local/bin/backup ; fi

        # echo -e " Backing up existing binaries to /usr/local/bin/backup" | tee -a "$LOGFILE"
        cp /usr/local/bin/${MNODE_BINARIES}* /usr/local/bin/backup
        rm /usr/local/bin/${MNODE_BINARIES}*

        curl -s "$GITAPI_URL" \
            | grep browser_download_url \
            | grep "$GITSTRING" \
            | cut -d '"' -f 4 \
            | wget -qi -
        TARBALL="$(find . -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")"

        if [[ $TARBALL == *.gz ]]
        then tar -xzf "$TARBALL"
        elif [[ $TARBALL == *.tgz ]]
        then tar -xzf "$TARBALL"
        else unzip "$TARBALL"
        fi
        rm -f "$TARBALL"
        cd  "$(\ls -1dt ./*/ | head -n 1)"
        find . -mindepth 2 -type f -print -exec mv {} . \;
        cp ${MNODE_BINARIES}* '/usr/local/bin'
        cd ..
        rm -r -f *
        cd
        cd /usr/local/bin
        chmod 777 ${MNODE_BINARIES}*

        echo -e " Starting masternodes after installation of new ${PROJECTt} binaries" >> "$LOGFILE"
        activate_masternodes_${PROJECT}
        sleep 2
        check_project

    else echo -e "${lightcyan} No new version is detected ${nocolor}\n"
        exit
    fi
}

function update_from_source() {
    # check for updates and build from source if installing binaries failed.

    echo -e "$(date +%m.%d.%Y_%H:%M:%S) : Running update_from_source function" | tee -a "$LOGFILE"
    cd $INSTALLDIR/temp
    rm -r -f $PROJECT*

    CURVERSION=$(cat $INSTALLDIR/temp/currentversion)
    NEWVERSION="$(curl -s $GITAPI_URL | grep tag_name)"
    if [ "$CURVERSION" != "$NEWVERSION" ]
    then 	echo -e " I couldn't download the new binaries, so I am now"
        echo -e " attempting to build new wallet version from source"
        sleep 3
        add-apt-repository -yu ppa:bitcoin/bitcoin
        apt-get -qq -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true update
        apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install build-essential \
            libcurl4-gnutls-dev protobuf-compiler libboost-all-dev autotools-dev automake \
            libboost-all-dev libssl-dev make autoconf libtool git apt-utils g++ \
            libprotobuf-dev pkg-config libudev-dev libqrencode-dev bsdmainutils \
            pkg-config libgmp3-dev libevent-dev jp2a pv virtualenv libdb4.8-dev libdb4.8++-dev
        systemctl stop ${PROJECT}*
        git clone $GIT_URL
        cd $PROJECT

        # this will compile wallet using directions from project.compile if it exists, if not use generic process
        if [ -s $INSTALLDIR/nodemaster/config/${PROJECT}/${PROJECT}.compile ]
        then echo -e " ${PROJECT}.compile found, building wallet from source instructions \n"  | tee -a "$LOGFILE"
            bash $INSTALLDIR/nodemaster/config/${PROJECT}/${PROJECT}.compile
        else echo -e " ${PROJECT}.compile not found, building wallet from generic instructions \n"  | tee -a "$LOGFILE"
            ./autogen.sh
            ./configure --disable-dependency-tracking --enable-tests=no --without-gui --without-miniupnpc --with-incompatible-bdb CFLAGS="-march=native" LIBS="-lcurl -lssl -lcrypto -lz"
            make
            make install
        fi

        cd /usr/local/bin && rm -f !"("activate_masternodes_$PROJECT")"
        cp $INSTALLDIR/temp/$PROJECT/src/{"$MNODE_BINARIES"-cli,"$MNODE_BINARIES"d,"$MNODE_BINARIES"-tx} /usr/local/bin/
        rm -rf $INSTALLDIR/temp/$PROJECT
        cd $INSTALLDIR/temp
        echo -e " Starting masternodes after building ${PROJECTt} from source" >> "$LOGFILE"
        activate_masternodes_$PROJECT
        sleep 2
        check_project
        echo -e " It looks like we couldn't rebuild ${PROJECTt} from source, either" >> "$LOGFILE"
        echo -e " Restoring original binaries from /usr/local/bin/backup" | tee -a "$LOGFILE"
        cp /usr/local/bin/backup/${MNODE_BINARIES}* /usr/local/bin/
        sleep 2
        check_restore
        reboot
        exit
    fi
}

function check_project() {
    # check if binaries already exist, skip installing crypto packages if they aren't needed
    dEXIST=$(ls /usr/local/bin | grep "${MNODE_DAEMON}")

    if [[ "${dEXIST}" ]]
    then echo -e " $(date +%m.%d.%Y_%H:%M:%S) : SUCCESS : ${MNODE_DAEMON} exists..." | tee -a "$LOGFILE"
        echo -e " New version installed : $NEWVERSION" | tee -a "$LOGFILE"
        echo -e "${lightgreen}  --> ${PROJECTt} was successfully updated, restarting VPS ${nocolor}\n" | tee -a "$LOGFILE"
        curl -s $GITAPI_URL | grep tag_name > $INSTALLDIR/temp/currentversion

        # Pull BLOCKEXP from $PROJECT.env
        BLOCKEX=$(grep ^BLOCKEXP $INSTALLDIR/nodemaster/config/"$PROJECT"/"$PROJECT".env)
        if [ -n "$BLOCKEX" ]
        then echo "$BLOCKEX" > $INFODIR/vps.BLOCKEXP.info
            sed -i "s/BLOCKEXP=//" $INFODIR/vps.BLOCKEXP.info
            BLOCKEXP=$(<$INFODIR/vps.BLOCKEXP.info)
            # echo -e " Block Explorer set to :"
            # echo -e " $BLOCKEXP \n"
        else echo -e "No block explorer was identified in $PROJECT.env \n" | tee -a "$LOGFILE"
        fi

        touch $INSTALLDIR/temp/shuttingdown
        remove_cron_function
        rm -f $INSTALLDIR/temp/updating
        rm -f $INSTALLDIR/temp/shuttingdown
        reboot
        shutdown -r now "Server is going down for upgrade."
        exit

    else echo -e "${lightred} $(date +%m.%d.%Y_%H:%M:%S) : ERROR : ${MNODE_DAEMON} does not exist...${nocolor}" | tee -a "$LOGFILE"
        echo -e "${yellow}  ** This update step failed, trying to autocorrect ... ${nocolor}\n" | tee -a "$LOGFILE"
    fi
}

function check_restore() {
    # check if binaries already exist, skip installing crypto packages if they aren't needed
    dEXIST=$(ls /usr/local/bin | grep "${MNODE_DAEMON}")

    if [[ "${dEXIST}" ]]
    then echo -e "${yellow} ** ${MNODE_DAEMON} is running...original binaries were restored${nocolor}" | tee -a "$LOGFILE"
        echo -e "  --> We will try to install this update again next time, rebooting... \n" | tee -a "$LOGFILE"
        remove_cron_function
        rm -f $INSTALLDIR/temp/updating
        rm -f $INSTALLDIR/temp/shuttingdown
        reboot
        shutdown -r now "Server is going down for upgrade."
        exit

    else echo -e "${lightred} Restoring the original binaries failed, ${MNODE_DAEMON} is not running... " | tee -a "$LOGFILE"
        echo -e " This shouldn't happen unless your source is unwell.  Make a fuss in Discord.${nocolor}" | tee -a "$LOGFILE"
        echo -e "${white}  --> I'm all out of options; your VPS may need service ${nocolor}\n " | tee -a "$LOGFILE"
        touch $INSTALLDIR/temp/shuttingdown
        remove_cron_function
        rm -f $INSTALLDIR/temp/updating
        rm -f $INSTALLDIR/temp/shuttingdown
        reboot
        shutdown -r now "Server is going down for upgrade."
    fi
}

# this is where the current update sequence begins

update_binaries
update_from_source
restore_cron_function
exit
