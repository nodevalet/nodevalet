#!/bin/bash
#check for updates and build from source if installing binaries failed. 

LOGFILE='/var/tmp/nodevalet/logs/autoupdate.log'
echo -e " `date +%m.%d.%Y_%H:%M:%S` : Running updatefromsource.sh" | tee -a "$LOGFILE"
INSTALLDIR='/var/tmp/nodevalet'
INFODIR='/var/tmp/nvtemp'
PROJECT=`cat $INFODIR/vpscoin.info`

cd /var/tmp/nodevalet/temp
rm -r -f $PROJECT*

# Pull GITAPI_URL from $PROJECT.env
GIT_API=`grep ^GITAPI_URL $INSTALLDIR/nodemaster/config/$PROJECT/$PROJECT.env`
echo "$GIT_API" > $INSTALLDIR/temp/GIT_API
sed -i "s/GITAPI_URL=//" $INSTALLDIR/temp/GIT_API
GITAPI_URL=$(<$INSTALLDIR/temp/GIT_API)

# Pull GIT URL from $PROJECT.env
GIT_URL=`grep ^GIT_URL $INSTALLDIR/nodemaster/config/$PROJECT/$PROJECT.env`
echo "$GIT_URL" > $INSTALLDIR/temp/GIT_URL
sed -i "s/GIT_URL=//" $INSTALLDIR/temp/GIT_URL
GIT_URL=$(<$INSTALLDIR/temp/GIT_URL)

# GITAPI_URL="https://api.github.com/repos/heliumchain/helium/releases/latest"
CURVERSION=`cat currentversion`
NEWVERSION="$(curl -s $GITAPI_URL | grep tag_name)"
if [ "$CURVERSION" != "$NEWVERSION" ]
then 	echo -e " I couldn't download the new binaries, so I am now" | tee -a "$LOGFILE"
	echo -e " attempting to build new wallet version from source" | tee -a "$LOGFILE"
	add-apt-repository -yu ppa:bitcoin/bitcoin
	apt-get -qq -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true update
	apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install build-essential \
	libcurl4-gnutls-dev protobuf-compiler libboost-all-dev autotools-dev automake \
	libboost-all-dev libssl-dev make autoconf libtool git apt-utils g++ \
	libprotobuf-dev pkg-config libudev-dev libqrencode-dev bsdmainutils \
	pkg-config libgmp3-dev libevent-dev jp2a pv virtualenv libdb4.8-dev libdb4.8++-dev
	systemctl stop $PROJECT* \
	&& git clone $GIT_URL \
	&& cd $PROJECT \
	&& ./autogen.sh \
	&& ./configure --disable-dependency-tracking --enable-tests=no --without-gui --without-miniupnpc --with-incompatible-bdb CFLAGS="-march=native" LIBS="-lcurl -lssl -lcrypto -lz" \
	&& make \
	&& make install \
	&& cd /usr/local/bin && rm -f !"("activate_masternodes_"$PROJECT"")" \
	&& cp $INSTALLDIR/$PROJECT/src/{"$PROJECT"-cli,"$PROJECT"d,"$PROJECT"-tx} /usr/local/bin/ \
	&& rm -rf $INSTALLDIR/$PROJECT \
	&& cd $INSTALLDIR/temp \
	&& rm -f updating \
	&& curl -s $GITAPI_URL \
		| grep tag_name > currentversion \
	&& echo -e " Rebooting after building new ${PROJECT} wallet\n" >> "$LOGFILE" \
	&& reboot
fi
