#!/bin/bash
#
# Setup a on RHEL/Centos 7 using kerberos authentication for the services defined in inputs.sh
# It also creates the same test user - krbtest

# Start of user inputs
###########################################################################
KRBCONFFILE="/etc/krb5.conf"
KRBCONFBKFILE="/etc/krb5_backup.conf"
KDCROOTPASSWORD="redhat"
USER1="krbtest"
###########################################################################
# End of user inputs

source ./inputs.sh
SERVERPACKAGES="krb5-workstation"

if [[ $EUID != "0" ]]
then
	echo "ERROR. You need to have root privileges to run this script"
	exit 1
else
	echo "Installing all the requested kerberos services on this server"
	echo "Also creating a test user krbtest"
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
	echo "copying backup file"
	cp -f $KRBCONFBKFILE $KRBCONFFILE
else
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

for SERVICE in ${SERVICES[@]}
do
# Add the keys of all the desired services to the default keytab file
	kadmin -p root/admin -w $KDCROOTPASSWORD -q "ktadd $SERVICE/$HOSTSERVER"
	echo "Service $SERVICE installed"
done

# Adding test user
userdel -f -r $USER1
useradd $USER1
