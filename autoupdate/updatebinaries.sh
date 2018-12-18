#!/bin/bash
#check for updates and install binaries if necessary

LOGFILE='/root/installtemp/autoupdate.log'
echo -e " `date +%m.%d.%Y_%H:%M:%S` : Running autoupdatebinaries.sh"  | tee -a "$LOGFILE"
cd /root/installtemp
INSTALLDIR='/root/installtemp'
PROJECT=`cat $INSTALLDIR/vpscoin.info`

# Pull GITAPI_URL from $PROJECT.env
GIT_API=`grep ^GITAPI_URL /root/code-red/nodemaster/config/${PROJECT}/${PROJECT}.env`
echo "$GIT_API" > $INSTALLDIR/GIT_API
sed -i "s/GITAPI_URL=//" $INSTALLDIR/GIT_API
GITAPI_URL=$(<$INSTALLDIR/GIT_API)

# GITAPI_URL="https://api.github.com/repos/heliumchain/helium/releases/latest"
CURVERSION=`cat currentversion`
NEWVERSION="$(curl -s $GITAPI_URL | grep tag_name)"
if [ "$CURVERSION" != "$NEWVERSION" ]
then echo -e " Installed version is : $CURVERSION" | tee -a "$LOGFILE"
     echo -e " New version detected : $NEWVERSION" | tee -a "$LOGFILE"
     echo -e " Attempting to install new binaries" | tee -a "$LOGFILE"
		touch updating
		systemctl stop $PROJECT* \
		| curl -s $GITAPI_URL \
		| grep browser_download_url \
  		| grep x86_64-linux-gnu.tar.gz \
  		| cut -d '"' -f 4 \
  		| wget -qi -
	TARBALL="$(find . -name "*x86_64-linux-gnu.tar.gz")"
	EXTRACTDIR=${TARBALL%-x86_64-linux-gnu.tar.gz}
	tar -xzf $TARBALL \
		&& cp -r $EXTRACTDIR/bin/. /usr/local/bin/ \
		&& curl -s $GITAPI_URL \
             		| grep tag_name > currentversion \
		&& rm -r $EXTRACTDIR \
		&& rm -f $TARBALL \
		&& rm -f updating
		&& echo -e " Rebooting after installation of new ${PROJECT} binaries\n" \
			| tee -a "$LOGFILE" \
		&& reboot
else echo -e " No new version is detected \n" | tee -a "$LOGFILE"
fi
