#!/bin/bash
# This file has common inputs the for the three scripts
REALM="MYSERVER.COM"
DOMAIN="myserver.com"
IPKDC=34.219.176.209
IPSERVER=54.201.74.104
IPCLIENT=34.217.174.234
HOSTS="/etc/hosts"
HOSTKDC="kdc.myserver.com"
HOSTSERVER="server.myserver.com"
HOSTCLIENT="client.myserver.com"
SERVICES=(host nfs)
SERVERKEYTABFILE="/tmp/server.keytab"
CLIENTKEYTABFILE="/tmp/client.keytab"
