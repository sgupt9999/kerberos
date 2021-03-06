#!/bin/bash
#
# Setup KDC server on RHEL/Centos 7. 
# All common inputs in inputs.sh

# Start of user inputs
###########################################################################
KDADMFILE="/var/kerberos/krb5kdc/kadm5.acl"
KDCCONFFILE="/var/kerberos/krb5kdc/kdc.conf"
KRBCONFFILE="/etc/krb5.conf"
KRBCONFBKFILE="/etc/krb5_backup.conf"
KDCDBPASSWORD="redhat"
KDCROOTPASSWD="redhat"
USER1="krbtest"
PASSWORD1="redhat"
# Firewalld must be up and running
FIREWALL="yes"
#FIREWALL="no"
###########################################################################
# End of user inputs

source ./inputs.sh
KDCPACKAGES="krb5-server pam_krb5"

if [[ $EUID != "0" ]]
then
	echo "ERROR. You need to have root privileges to run this script"
	exit 1
else
	echo "###########################################################################"
	echo "This script will install KDC on this machine"
	echo "Also creating a test user krbtest"
	echo "###########################################################################"
	sleep 5
fi

# Comment out all existing entries for the host names from /etc/hosts
sed -i "s/.*$HOSTKDC/#&/g" $HOSTS
sed -i "s/.*$HOSTSERVER/#&/g" $HOSTS
sed -i "s/.*$HOSTCLIENT/#&/g" $HOSTS
echo "$IPKDC $HOSTKDC" >> $HOSTS
echo "$IPSERVER $HOSTSERVER" >> $HOSTS
echo "$IPCLIENT $HOSTCLIENT" >> $HOSTS


if yum list installed krb5-server > /dev/null 2>&1
then
	systemctl is-active -q krb5kdc && {
		systemctl stop krb5kdc
		systemctl -q disable krb5kdc
	}

	systemctl is-active -q kadmin && {
		systemctl stop kadmin
		systemctl -q disable kadmin
	}
	echo "Removing packages............."
	yum -y -q remove $KDCPACKAGES > /dev/null 2>&1
	rm -rf /var/kerberos/krb5kdc	
	echo "Done"
fi

echo "Installing $KDCPACKAGES.........."
yum -y -q install $KDCPACKAGES > /dev/null 2>&1
echo "Done"

echo "Updating kdc.conf"
sed -i "s/EXAMPLE.COM/$REALM/" $KDCCONFFILE

echo "Updating kadm5.acl"
sed -i "s/EXAMPLE.COM/$REALM/" $KDADMFILE

# This file is installed by krb5-libs which comes pre-installed. Make a backup if one doesnt already
# exist
if [ -f $KRBCONFBKFILE ]
then
	cp -f $KRBCONFBKFILE $KRBCONFFILE
else
	cp -f $KRBCONFFILE $KRBCONFBKFILE
fi

echo "Updating krb5.conf"
sed -i "s/#//g" $KRBCONFFILE
sed -i "s/EXAMPLE.COM/$REALM/g" $KRBCONFFILE
sed -i "s/kerberos.example.com/$HOSTKDC/g" $KRBCONFFILE
sed -i "s/example.com/$DOMAIN/g" $KRBCONFFILE

echo "Creating KDC database"
kdb5_util create -s -P $KDCDBPASSWORD -r $REALM > /dev/null 2>&1
echo "Done"

systemctl start krb5kdc
systemctl start kadmin

kadmin.local -q "addprinc -pw $KDCROOTPASSWD root/admin" > /dev/null 2>&1
kadmin.local -q "addprinc -pw $PASSWORD1 $USER1" > /dev/null 2>&1

rm -f $SERVERKEYTABFILE
rm -f $CLIENTKEYTABFILE
for SERVICE in ${SERVICES[@]}
do
	kadmin.local -q "delprinc -force $SERVICE/$HOSTSERVER"
	kadmin.local -q "addprinc -randkey $SERVICE/$HOSTSERVER"
	kadmin.local -q "delprinc -force $SERVICE/$HOSTCLIENT"
	kadmin.local -q "addprinc -randkey $SERVICE/$HOSTCLIENT"
done

if [[ $FIREWALL == "yes" ]]
then
	if systemctl is-active -q firewalld
	then
		echo "Making firewall changes"
		firewall-cmd -q --permanent --add-port 88/tcp
		firewall-cmd -q --permanent --add-port 88/udp
		firewall-cmd -q --permanent --add-port 749/tcp
		firewall-cmd -q --reload
		echo "Done"
	else
		echo "Firewalld not running. No changes made to firewall"
	fi
fi

# Adding kerberos to PAM
authconfig --enablekrb5 --update

# Adding kerberos to ssh client
sed -i 's/.*GSSAPIAuthentication.*/GSSAPIAuthentication yes/g' /etc/ssh/ssh_config
sed -i 's/.*GSSAPIDelegateCredentials.*/GSSAPIDelegateCredentials yes/g' /etc/ssh/ssh_config
systemctl reload sshd


systemctl restart krb5kdc
systemctl restart kadmin
systemctl -q enable krb5kdc
systemctl -q enable kadmin

echo "###########################################################################"
echo "KDC SERVER CREATED"
echo "###########################################################################"
