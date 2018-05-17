#!/bin/bash
# This file has common inputs the for the three scripts
REALM="MYSERVER.COM"
DOMAIN="myserver.com"
IPKDC=172.31.25.79
IPSERVER=172.31.17.170
IPCLIENT=172.31.20.93
HOSTS="/etc/hosts"
HOSTKDC="kdc.myserver.com"
HOSTSERVER="server.myserver.com"
HOSTCLIENT="client.myserver.com"
SERVICES=(host nfs)
SERVERKEYTABFILE="/tmp/server.keytab"
CLIENTKEYTABFILE="/tmp/client.keytab"
