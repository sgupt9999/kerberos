#!/bin/bash
#
# Setting up a kerberos client for all requested services
# It will also create a test user krbtest

# Start of user inputs
###########################################################################
KRBCONFFILE="/etc/krb5.conf"
KRBCONFBKFILE="/etc/krb5_backup.conf"
KDCROOTPASSWORD="redhat"
USER1="krbtest"
###########################################################################
# End of user inputs

source ./inputs.sh
CLIENTPACKAGES="krb5-workstation"


if [[ $EUID != "0" ]]
then
	echo "ERROR. You need to have root privileges to run this script"
	exit 1
else
	echo "Setting up authentication for all requested kerberos services"
	echo "Also creating a test user krbtest" 
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
sed -i "s/#//g" $KRBCONFFILE
sed -i "s/EXAMPLE.COM/$REALM/g" $KRBCONFFILE
sed -i "s/kerberos.example.com/$HOSTKDC/g" $KRBCONFFILE
sed -i "s/example.com/$DOMAIN/g" $KRBCONFFILE

for SERVICE in ${SERVICES[@]}
do
# Add the keys of all the desired services to the default keytab file
        kadmin -p root/admin -w $KDCROOTPASSWORD -q "ktadd $SERVICE/$HOSTCLIENT"
        echo "Service $SERVICE installed"
done


# Adding test user
userdel -f -r $USER1
useradd $USER1
