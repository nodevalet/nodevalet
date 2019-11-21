#!/bin/bash
# attempt to bootstrap blockchain and then clonesync_all

LOGFILE='/var/tmp/nodevalet/logs/maintenance.log'
INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
MNS=$(<$INFODIR/vpsnumber.info)
PROJECT=$(<$INFODIR/vpscoin.info)
PROJECTl=${PROJECT,,}
PROJECTt=${PROJECTl~}
MNODE_DAEMON=$(<$INFODIR/vpsmnode_daemon.info)
HNAME=$(<$INFODIR/vpshostname.info)

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

# extglob was necessary to make rm -- ! possible
shopt -s extglob

function shutdown_mn1() {
    # stop and disable mn1
    echo -e "${yellow} Bootstrap needs to shut down the 1st masternode:${nocolor}"
    sudo systemctl disable "${PROJECT}"_n1 > /dev/null 2>&1
    sudo systemctl stop "${PROJECT}"_n1
    echo -e " ${lightred}--> Masternode ${PROJECT}_n1 has been disabled...${nocolor}\n"
}

function remove_crons() {
    # disable the crons that could cause problems
    crontab -l | grep -v '/var/tmp/nodevalet/maintenance/rebootq.sh'  | crontab -
    crontab -l | grep -v '/var/tmp/nodevalet/maintenance/makerun.sh'  | crontab -
    crontab -l | grep -v '/var/tmp/nodevalet/maintenance/checkdaemon.sh'  | crontab -
}

function restore_crons() {
    # restore maintenance crons that were previously disabled
    echo -e "${yellow} Re-enabling crontabs that were previously disabled:${nocolor}"
    echo -e "${white}  --> Check for & reboot if needed to install updates every 10 hours${nocolor}"
    (crontab -l ; echo "59 */10 * * * /var/tmp/nodevalet/maintenance/rebootq.sh") | crontab -
    echo -e "${white}  --> Make sure all daemons are running every 10 minutes${nocolor}"
    (crontab -l ; echo "*/10 * * * * /var/tmp/nodevalet/maintenance/makerun.sh") | crontab -
    echo -e "${white}  --> Check for stuck blocks every 30 minutes${nocolor}"
    (crontab -l ; echo "1,31 * * * * /var/tmp/nodevalet/maintenance/checkdaemon.sh") | crontab -
}

function bootstrap() {
    #check for updates and install binaries if necessary
    echo -e "$(date +%m.%d.%Y_%H:%M:%S) : Running bootstrap function"
    echo -e "$(date +%m.%d.%Y_%H:%M:%S) : Bootstrap is looking for $PROJECTt bootstrap"

# curl -s https://api.github.com/repos/theaudaxproject/audax/releases/latest | grep tag_name
# https://api.github.com/repos/theaudaxproject/audax/releases/latest

# this downloads the bootstrap file into the current folder
# curl -s https://api.github.com/repos/theaudaxproject/audax/releases/latest | grep browser_download_url | grep bootstrap | cut -d '"' -f 4 | wget -qi -

    
    # add a check to see if blockchain is already synced, if it is, exit


    # make provisions for snapshot files instead of bootstraps
    if curl -s $GITAPI_URL | grep browser_download_url | grep napshot | grep .zip
    then remove_crons 
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Bootstrap.sh detected $PROJECTt snapshot file" | tee -a "$LOGFILE"
        echo -e " --> Downloading and installing $PROJECTt blockchain" | tee -a "$LOGFILE"
        echo -e " "
        touch $INSTALLDIR/temp/updating
        rm -rf $INSTALLDIR/temp/bootstrap > /dev/null 2>&1
        mkdir $INSTALLDIR/temp/bootstrap
        cd $INSTALLDIR/temp/bootstrap

        # download bootstrap file
        curl -s "$GITAPI_URL" \
            | grep browser_download_url \
            | grep napshot \
            | grep .zip \
            | cut -d '"' -f 4 \
            | wget -qi -

        BOOTSTRAPZIP="$(find . -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")"

        if [[ $BOOTSTRAPZIP == *.gz ]]
        then tar -xzf "$BOOTSTRAPZIP"
        elif [[ $BOOTSTRAPZIP == *.zip ]]
        then unzip "$BOOTSTRAPZIP"
        else :
        fi

        rm -f "$BOOTSTRAPZIP"
        chown -R masternode:masternode $INSTALLDIR/temp/bootstrap
        chmod -R g=u $INSTALLDIR/temp/bootstrap

        # need to shutdown 1st masternode
        shutdown_mn1

        echo -e "${lightred}  Clearing blockchain from ${PROJECT}_n1...${nocolor}"
        cd /var/lib/masternodes/"${PROJECT}"1
        sudo rm -rf !("wallet.dat"|"masternode.conf")
        sleep .25

        # copy blocks/chainstate/sporks with permissions (cp -rp) or it will fail
        echo -e "${white}  Copying bootstrap data to ${PROJECT}_n1...${nocolor}"
        cp -rp $INSTALLDIR/temp/bootstrap/blocks /var/lib/masternodes/"${PROJECT}"1/blocks
        cp -rp $INSTALLDIR/temp/bootstrap/chainstate /var/lib/masternodes/"${PROJECT}"1/chainstate
        cp -rp $INSTALLDIR/temp/bootstrap/sporks /var/lib/masternodes/"${PROJECT}"1/sporks

        # remove bootstrap blockchain
        rm -rf $INSTALLDIR/temp/bootstrap > /dev/null 2>&1

        echo -e "${lightcyan} --> The 1st masternode has been bootstrapped${nocolor}\n"

        # this was previously used to navigate to the right folder in case of empty root folders
        # cd  "$(\ls -1dt ./*/ | head -n 1)"
        # find . -mindepth 2 -type f -print -exec mv {} . \;

        echo -e " --> Restarting $PROJECTt Masternode n1 \n" | tee -a "$LOGFILE"
        # echo -e " Starting masternodes after installation of bootstrap" >> "$LOGFILE"
        sudo systemctl enable "${PROJECT}"_n1 > /dev/null 2>&1
        sudo systemctl start "${PROJECT}"_n1
        sleep 2

    elif curl -s $GITAPI_URL | grep browser_download_url | grep bootstrap
    then echo -e " $(date +%m.%d.%Y_%H:%M:%S) : Bootstrap.sh detected $PROJECTt bootstrap file" | tee -a "$LOGFILE"
        echo -e " --> Downloading and installing $PROJECTt blockchain" | tee -a "$LOGFILE"
        echo -e " "
        touch $INSTALLDIR/temp/updating
        rm -rf $INSTALLDIR/temp/bootstrap > /dev/null 2>&1
        mkdir $INSTALLDIR/temp/bootstrap
        cd $INSTALLDIR/temp/bootstrap

        # download bootstrap file
        curl -s "$GITAPI_URL" \
            | grep browser_download_url \
            | grep bootstrap \
            | cut -d '"' -f 4 \
            | wget -qi -

        BOOTSTRAPZIP="$(find . -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")"

        if [[ $BOOTSTRAPZIP == *.gz ]]
        then tar -xzf "$BOOTSTRAPZIP"
        elif [[ $BOOTSTRAPZIP == *.zip ]]
        then unzip "$BOOTSTRAPZIP"
        elif [[ $BOOTSTRAPZIP == *.dat ]]
        then chown -R masternode:masternode $INSTALLDIR/temp/bootstrap
        chmod -R g=u $INSTALLDIR/temp/bootstrap
        cp -p $INSTALLDIR/temp/bootstrap/$BOOTSTRAPZIP /var/lib/masternodes/"${PROJECT}"1/
        else :
        fi

        rm -f "$BOOTSTRAPZIP"
        chown -R masternode:masternode $INSTALLDIR/temp/bootstrap
        chmod -R g=u $INSTALLDIR/temp/bootstrap

        # need to shutdown 1st masternode
        shutdown_mn1

        echo -e "${lightred}  Clearing blockchain from ${PROJECT}_n1...${nocolor}"
        cd /var/lib/masternodes/"${PROJECT}"1
        sudo rm -rf !("wallet.dat"|"masternode.conf"|"bootstrap.dat")
        sleep .25

        # copy blocks/chainstate/sporks with permissions (cp -rp) or it will fail
        echo -e "${white}  Copying bootstrap data to ${PROJECT}_n1...${nocolor}"
        cp -rp $INSTALLDIR/temp/bootstrap/blocks /var/lib/masternodes/"${PROJECT}"1/blocks
        cp -rp $INSTALLDIR/temp/bootstrap/chainstate /var/lib/masternodes/"${PROJECT}"1/chainstate
        cp -rp $INSTALLDIR/temp/bootstrap/sporks /var/lib/masternodes/"${PROJECT}"1/sporks

        # remove bootstrap blockchain
        rm -rf $INSTALLDIR/temp/bootstrap > /dev/null 2>&1

        echo -e "${lightcyan} --> The 1st masternode has been bootstrapped${nocolor}\n"

        # this was previously used to navigate to the right folder in case of empty root folders
        # cd  "$(\ls -1dt ./*/ | head -n 1)"
        # find . -mindepth 2 -type f -print -exec mv {} . \;

        echo -e " --> Restarting $PROJECTt Masternode n1 \n" | tee -a "$LOGFILE"
        # echo -e " Starting masternodes after installation of bootstrap" >> "$LOGFILE"
        sudo systemctl enable "${PROJECT}"_n1 > /dev/null 2>&1
        sudo systemctl start "${PROJECT}"_n1
        sleep 2
    else echo -e " No bootstrap file is detected${nocolor}\n"
        checksync 1
        exit
    fi
}

# this is where the bootstrap sequence begins
bootstrap
rm -rf $INSTALLDIR/temp/updating
restore_crons
bash $INSTALLDIR/maintenance/clonesync_all.sh
exit
