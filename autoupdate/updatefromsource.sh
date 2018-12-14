#!/bin/bash
#check for updates and build from source if installing binaries failed. 

LOGFILE='/root/installtemp/autoupdate.log'
echo -e "`date +%m.%d.%Y_%H:%M:%S` : Running updatefromsource.sh" | tee -a "$LOGFILE"
 
cd /root/installtemp
GITAPI_URL="https://api.github.com/repos/heliumchain/helium/releases/latest"
CURVERSION=`cat currentversion`
NEWVERSION="$(curl -s $GITAPI_URL | grep tag_name)"
if [ "$CURVERSION" != "$NEWVERSION" ]
then echo -e "Installed version is $CURVERSION; new version detected: $NEWVERSION" | tee -a "$LOGFILE"
	echo -e "I couldn't download the new binaries, so I am now" | tee -a "$LOGFILE"
	echo -e "attempting to build new wallet version from source" | tee -a "$LOGFILE"
	add-apt-repository -yu ppa:bitcoin/bitcoin
	apt-get -qq -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true update
	apt-get -qqy -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install build-essential \
	libcurl4-gnutls-dev protobuf-compiler libboost-all-dev autotools-dev automake \
	libboost-all-dev libssl-dev make autoconf libtool git apt-utils g++ \
	libprotobuf-dev pkg-config libudev-dev libqrencode-dev bsdmainutils \
	pkg-config libgmp3-dev libevent-dev jp2a pv virtualenv libdb4.8-dev libdb4.8++-dev
	systemctl stop 'helium*' \
	&& git clone https://github.com/heliumchain/helium.git \
	&& cd helium \
	&& ./autogen.sh \
	&& ./configure --disable-dependency-tracking --enable-tests=no --without-gui --without-miniupnpc --with-incompatible-bdb CFLAGS="-march=native" LIBS="-lcurl -lssl -lcrypto -lz" \
	&& make \
	&& make install \
        && cd /usr/local/bin && rm -f !"("activate_masternodes_helium")" \
	&& cp /root/installtemp/helium/src/{helium-cli,heliumd,helium-tx} /usr/local/bin/ \
        && rm -rf root/installtemp/helium \
        && cd /root/installtemp \
        && curl -s $GITAPI_URL \
             | grep tag_name > currentversion \
        && reboot
fi
