
#!/bin/bash
# install Ksplice Uptrack

sudo apt-get install libgtk2-perl consolekit iproute libck-connector0 libcroco3 libglade2-0 libpam-ck-connector librsvg2-2 librsvg2-common python-cairo python-dbus python-gi python-glade2 python-gobject-2 python-gtk2 python-pycurl python-yaml dbus-x11 -y
sudo wget https://ksplice.oracle.com/uptrack/dist/xenial/ksplice-uptrack.deb
sudo dpkg -i ksplice-uptrack.deb
sudo sed -i "s/autoinstall = no/autoinstall = yes/" /etc/uptrack/uptrack.conf
sudo chmod 755 /etc/cron.d/uptrack
sudo uptrack-upgrade -y
