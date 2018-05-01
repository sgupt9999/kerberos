#!/bin/bash
#
# Setup KDC server on RHEL/Centos 7. First just setting up a ssh server. More services can
# be added later

# Start of user inputs
REALM="MYSERVER.COM"
DOMAIN="mylabserver.com"
IPKDC=172.31.111.114
IPSERVER=0.0.0.0
IPCLIENT=0.0.0.0
HOSTS="/etc/hosts"
HOSTKDC="garfield99996.mylabserver.com"
HOSTSERVER="garfield99995.mylabserver.com"
HOSTCLIENT="garfield99994.mylabserver.com"
#FIREWALL="yes"
FIREWALL="no"
# End of user inputs


KDCPACKAGES="krb5-server"
SERVERPACKAGES="krb5-workstation"
CLIENTPACKAGES="krb5-workstation pam_krb5"


if [[ $EUID != "0" ]]
then
	echo "ERROR. You need to have root privileges to run this script"
	exit 1
fi

# If hosts already in the file then delete it
line-number=`grep -i $HOSTKDC $HOSTS | head -n 1 | cut -d: -f1`
sed -i 's/$HOSTKDC/#&/' $HOSTS

if yum list installed $KDCPACKAGES
then
	systemctl is-active -q krb5kdc && {
		systemctl stop krb5kdc
		sytemctl disable krb5kdc
	}

	systemctl is-active -q kadmin && {
		systemctl stop kadmin
		sytemctl disable kadmin

	echo "Removing packages............."
	yum -y -q remove $KDCPACKAGES > /dev/null 2>&1
	echo "Done"
fi

echo "Installing $KDCPACKAGES"
yum -y -q install $KDCPACKAGES > /dev/null 2>&1
echo "Done"

