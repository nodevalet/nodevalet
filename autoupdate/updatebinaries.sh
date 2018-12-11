#!/bin/bash
#check for updates and install binaries if necessary

GITAPI_URL="https://api.github.com/repos/heliumchain/helium/releases/latest"
CURVERSION=`cat currentversion`
NEWVERSION="$(curl -s $GITAPI_URL | grep tag_name)"
if [ "$CURVERSION" != "$NEWVERSION" ]
then curl -s $GITAPI_URL \
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
		&& reboot
fi
