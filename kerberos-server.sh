#!/bin/bash
#
# Setup a login server on RHEL/Centos 7 using kerberos authentication.

# Start of user inputs
REALM="MYSERVER.COM"
DOMAIN="mylabserver.com"
IPKDC=172.31.111.114
IPSERVER=0.0.0.0
IPCLIENT=172.31.125.24
HOSTS="/etc/hosts"
HOSTKDC="garfield99996.mylabserver.com"
HOSTSERVER="garfield99995.mylabserver.com"
HOSTCLIENT="garfield99994.mylabserver.com"
KDADMFILE="/var/kerberos/krb5kdc/kadm5.acl"
KDCCONFFILE="/var/kerberos/krb5kdc/kdc.conf"
KRBCONFFILE="/etc/krb5.conf"
KRBCONFBKFILE="/etc/krb5_backup.conf"


KDCDBPASSWORD="redhat"
KDCROOTPASSWD="redhat"
USER1="krbtest"

# The host service is used for login or ssh
SERVICE1="host/$HOSTSERVER"

#FIREWALL="yes"
FIREWALL="no"
# End of user inputs


SERVERPACKAGES="krb5-workstation"
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


echo "Installing $SERVERPACKAGES"
yum -y -q install $SERVERPACKAGES > /dev/null 2>&1
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
sed -i "s/#.*EXAMPLE.COM.*/$REALM = {/" $KRBCONFFILE
sed -i "s/#.*kdc.*/kdc = $HOSTKDC/" $KRBCONFFILE
sed -i "s/#.*admin_server.*/admin_server = $HOSTKDC/" $KRBCONFFILE
sed -i "s/#.*}/}/" $KRBCONFFILE
sed -i "s/#.*.example.com.*/.$DOMAIN = $REALM/" $KRBCONFFILE
sed -i "s/#.*example.com.*/$DOMAIN = $REALM/" $KRBCONFFILE

# Add the host service to the KDC database and save the key to a local keytab file
kadmin -w $KDCDBPASSWORD -q "addprinc -randkey $SERVICE"
kadmin -w $KDCDBPASSWORD -q "ktadd $SERVICE"

# Add user for testing
useradd $USER1
