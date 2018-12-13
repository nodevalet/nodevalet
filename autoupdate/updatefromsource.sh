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
