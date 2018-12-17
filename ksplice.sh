
#!/bin/bash
# install Ksplice Uptrack

sudo apt-get -o=Dpkg::Use-Pty=0 -o=Acquire::ForceIPv4=true install libgtk2-perl consolekit iproute libck-connector0 libcroco3 libglade2-0 libpam-ck-connector librsvg2-2 librsvg2-common python-cairo python-dbus python-gi python-glade2 python-gobject-2 python-gtk2 python-pycurl python-yaml dbus-x11 -y
sudo wget https://ksplice.oracle.com/uptrack/dist/xenial/ksplice-uptrack.deb
sudo dpkg -i ksplice-uptrack.deb
sudo sed -i "s/autoinstall = no/autoinstall = yes/" /etc/uptrack/uptrack.conf
sudo chmod 755 /etc/cron.d/uptrack
rm ksplice-uptrack.deb
sudo uptrack-upgrade -y
exit

# What next? Here are some ways to use Kspliec Uptrack:
#
# uptrack-show – Show the patches that have been applied to your kernel.
# uptrack-show –available – Show patches that are available to be installed.
# uptrack-remove – Remove a patch from your active kernel.
# uptrack-uname -a – Display the active kernel version. Note that Ksplice does not alter the normal uname output, so this is necessary to determine what “actual” kernel version you are running.
# uptrack-upgrade – Display (and, if the -y flag is given, install) available updates to your kernel.
