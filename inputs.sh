#!/bin/bash
# This file has common inputs the for the three scripts
REALM="MYSERVER.COM"
DOMAIN="mylabserver.com"
IPKDC=172.31.111.114
IPSERVER=172.31.124.129
IPCLIENT=172.31.125.24
HOSTS="/etc/hosts"
HOSTKDC="garfield99996.mylabserver.com"
HOSTSERVER="garfield99994.mylabserver.com"
HOSTCLIENT="garfield99995.mylabserver.com"
SERVICES=(host nfs)
SERVERKEYTABFILE="/tmp/server.keytab"
CLIENTKEYTABFILE="/tmp/client.keytab"
