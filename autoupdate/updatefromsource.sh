#check for updates and build from source if installing binaries failed. 
 
cd /root/installtemp
GITAPI_URL="https://api.github.com/repos/heliumchain/helium/releases/latest"
CURVERSION=`cat currentversion`
NEWVERSION="$(curl -s $GITAPI_URL | grep tag_name)"
if [ "$CURVERSION" != "$NEWVERSION" ]
then systemctl stop 'helium*' \
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
