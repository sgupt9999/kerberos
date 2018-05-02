#!/bin/bash
#
# Setup KDC server on RHEL/Centos 7. First just setting up a ssh server. More services can
# be added later

# Start of user inputs
REALM="MYSERVER.COM"
DOMAIN="mylabserver.com"
IPKDC=172.31.111.114
IPSERVER=172.31.124.129
IPCLIENT=172.31.125.24
HOSTS="/etc/hosts"
HOSTKDC="garfield99996.mylabserver.com"
HOSTSERVER="garfield99994.mylabserver.com"
HOSTCLIENT="garfield99995.mylabserver.com"
KRBCONFFILE="/etc/krb5.conf"
KRBCONFBKFILE="/etc/krb5_backup.conf"

USER1="krbtest"

# End of user inputs


CLIENTPACKAGES="krb5-workstation pam_krb5"


if [[ $EUID != "0" ]]
then
	echo "ERROR. You need to have root privileges to run this script"
	exit 1
fi

# Comment out all existing entries for the host names from /etc/hosts
sed -i "s/.*$HOSTKDC/#&/g" $HOSTS
sed -i "s/.*$HOSTSERVER/#&/g" $HOSTS
sed -i "s/.*$HOSTCLIENT/#&/g" $HOSTS
echo "$IPKDC $HOSTKDC" >> $HOSTS
echo "$IPSERVER $HOSTSERVER" >> $HOSTS
echo "$IPCLIENT $HOSTCLIENT" >> $HOSTS


echo "Installing $CLIENTPACKAGES"
yum -y -q install $CLIENTPACKAGES > /dev/null 2>&1
echo "Done"

# This file is installed by krb5-libs which comes pre-installed. Make a backup if one doesnt already
# exist
if [ -f $KRBCONFBKFILE ]
then
	echo "Backup file exists"
	cp -f $KRBCONFBKFILE $KRBCONFFILE
else
	echo "Creating backup file"
	cp -f $KRBCONFFILE $KRBCONFBKFILE
fi


echo "Updating krb5.conf"
sed -i "s/#.*default_realm.*/default_realm = $REALM/" $KRBCONFFILE
sed -i "s/#.*kdc.*/kdc = $HOSTKDC/" $KRBCONFFILE
sed -i "s/#.*admin_server.*/admin_server = $HOSTKDC/" $KRBCONFFILE
sed -i "s/#.*}/}/" $KRBCONFFILE
sed -i "s/#.*.example.com.*=.*EXAMPLE.COM.*/.$DOMAIN = $REALM/" $KRBCONFFILE
sed -i "s/#.*example.com.*=.*EXAMPLE.COM.*/$DOMAIN = $REALM/" $KRBCONFFILE
# Not sure why but the EXAMPLE.COM is changing example.com as well. This section of code can be
# cleaned up
sed -i "s/#.*EXAMPLE.COM.*/$REALM = {/" $KRBCONFFILE

# Adding test user
userdel -f -r $USER1
useradd $USER1
