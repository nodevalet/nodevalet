#!/bin/bash
# attempt to bootstrap blockchain and then clonesync_all

# Set common variables
. /var/tmp/nodevalet/maintenance/vars.sh

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

# extglob was necessary to make rm -- ! possible
shopt -s extglob

function check_if_synced() {
    # check if all masternodes are already synced
    dSYNCED=$(ls /var/tmp/nodevalet/temp | grep nosync)

    if [[ "${dSYNCED}" ]]
    then echo -e "${lightred} One or more masternodes are not synced.${nocolor}\n"
    else echo -e "${lightcyan} All masternodes seem to be synced, no need to bootstrap.${nocolor}\n"
        rm -f $INSTALLDIR/temp/bootstrapping --force
        exit
    fi
}

function shutdown_mn1() {
    # stop and disable mn1
    echo -e "${yellow} Bootstrap needs to shut down the 1st masternode:${nocolor}"
    sudo systemctl disable "${PROJECT}"_n1 > /dev/null 2>&1
    sudo systemctl stop "${PROJECT}"_n1
    echo -e " ${lightred}--> Masternode ${PROJECT}_n1 has been disabled...${nocolor}\n"
}

function remove_cron_function() {
    # disable the crons that could cause problems
    . /var/tmp/nodevalet/maintenance/remove_crons.sh
}

function restore_cron_function() {
    # restore maintenance crons that were previously disabled
    . /var/tmp/nodevalet/maintenance/restore_crons.sh
}

function bootstrap() {
    #check for updates and install binaries if necessary
    echo -e "$(date +%m.%d.%Y_%H:%M:%S) : Running bootstrap function"
    echo -e "$(date +%m.%d.%Y_%H:%M:%S) : Bootstrap is looking for $PROJECTt bootstrap"

    # curl -s https://api.github.com/repos/theaudaxproject/audax/releases/latest | grep tag_name
    # https://api.github.com/repos/theaudaxproject/audax/releases/latest

    # this downloads the bootstrap file into the current folder
    # curl -s https://api.github.com/repos/theaudaxproject/audax/releases/latest | grep browser_download_url | grep bootstrap | cut -d '"' -f 4 | wget -qi -

    # make provisions for snapshot files instead of bootstraps
    if curl -s $GITAPI_URL | grep browser_download_url | grep napshot | grep .zip
    then remove_cron_function
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : ${lightcyan}Bootstrap.sh detected $PROJECTt snapshot file${nocolor}" | tee -a "$LOGFILE"
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
            | wget -i -

elif curl -s $GITAPI_URL | grep browser_download_url | grep napshot | grep .tgz
    then remove_cron_function
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : ${lightcyan}Bootstrap.sh detected $PROJECTt snapshot file${nocolor}" | tee -a "$LOGFILE"
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
            | grep .tgz \
            | cut -d '"' -f 4 \
            | wget -i -

elif curl -s $GITAPI_URL | grep browser_download_url | grep bootstrap
    then remove_cron_function
        echo -e " $(date +%m.%d.%Y_%H:%M:%S) : ${lightcyan}Bootstrap.sh detected $PROJECTt bootstrap file${nocolor}" | tee -a "$LOGFILE"
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
            | wget -i -

    else echo -e " ${lightcyan}No bootstrap file is detected${nocolor}\n"
        rm -f $INSTALLDIR/temp/bootstrapping --force
        # checksync 1 ; not sure if this line is needed or not
        exit
    fi

    echo -e "\n ${lightcyan}Bootstrap has been downloaded, extracting...${nocolor}\n"
    BOOTSTRAPZIP="$(find . -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")"

    if [[ $BOOTSTRAPZIP == *.gz ]]
    then tar -vxzf "$BOOTSTRAPZIP"
elif [[ $BOOTSTRAPZIP == *.tgz ]]
    then tar -vxzf "$BOOTSTRAPZIP"
elif [[ $BOOTSTRAPZIP == *.zip ]]
    then unzip "$BOOTSTRAPZIP"
    else echo -e " ${lightred}An unknown bootstrap file was downloaded"  | tee -a "$LOGFILE"
        echo -e " The name of the file was $BOOTSTRAPZIP."  | tee -a "$LOGFILE"
        echo -e " I am not quite sure to do with that, aborting bootstrap.${nocolor}\n"
        exit
    fi

    rm -f "$BOOTSTRAPZIP"

    # take ownership of bootstrap files and folders
    chown -R masternode:masternode $INSTALLDIR/temp/bootstrap
    chmod -R g=u $INSTALLDIR/temp/bootstrap

    # need to shutdown 1st masternode
    shutdown_mn1

    echo -e "${lightred}  Clearing blockchain from ${PROJECT}_n1...${nocolor}"
    cd /var/lib/masternodes/"${PROJECT}"1
    cp wallet.dat wallet_backup.$(date +%m.%d.%y).dat
    sudo rm -rf !("wallet_backup.$(date +%m.%d.%y).dat"|"masternode.conf")
    sleep .25

    # copy blocks/chainstate/sporks with permissions (cp -rp) or it will fail
    echo -e "${white}  Copying bootstrap data to ${PROJECT}_n1...${nocolor}"
    [ -d "$INSTALLDIR/temp/bootstrap/blocks" ] && cp -rp $INSTALLDIR/temp/bootstrap/blocks /var/lib/masternodes/"${PROJECT}"1/blocks
    [ -d "$INSTALLDIR/temp/bootstrap/chainstate" ] && cp -rp $INSTALLDIR/temp/bootstrap/chainstate /var/lib/masternodes/"${PROJECT}"1/chainstate
    [ -d "$INSTALLDIR/temp/bootstrap/sporks" ] && cp -rp $INSTALLDIR/temp/bootstrap/sporks /var/lib/masternodes/"${PROJECT}"1/sporks
    [ -d "$INSTALLDIR/temp/bootstrap/zerocoin" ] && cp -rp $INSTALLDIR/temp/bootstrap/zerocoin /var/lib/masternodes/"${PROJECT}"1/zerocoin

    # remove bootstrap blockchain
    rm -rf $INSTALLDIR/temp/bootstrap > /dev/null 2>&1

    echo -e "${lightcyan} --> The 1st masternode has been bootstrapped${nocolor}\n"

    # this was previously used to navigate to the right folder in case of empty root folders
    # cd  "$(\ls -1dt ./*/ | head -n 1)"
    # find . -mindepth 2 -type f -print -exec mv {} . \;

    echo -e " --> $(date +%H:%M:%S) : ${lightgreen}Restarting the first $PROJECTt masternode${nocolor}\n" | tee -a "$LOGFILE"
    sudo systemctl enable "${PROJECT}"_n1 > /dev/null 2>&1
    sudo systemctl start "${PROJECT}"_n1
    sleep 2
}

# this is where the bootstrap sequence begins
check_if_synced
bootstrap
rm -rf $INSTALLDIR/temp/updating

# exit if there is only one masternode
if [ $MNS = 1 ]
then echo -e " This VPS has only one masternode, skipping clonesync_all.sh\n"  | tee -a "$LOGFILE"
restore_cron_function
else bash $INSTALLDIR/maintenance/clonesync_all.sh
fi

rm -f $INSTALLDIR/temp/bootstrapping --force
exit
