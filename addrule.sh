#!/bin/bash

#/usr/bin/netstat -antlp | grep 13164 | grep ESTAB | awk '{print $5}' | awk -F: '{print $1}' | sort -n | uniq -c | sort -n | awk '{if($1>4){print "/sbin/ipset add badip "$2}}' > badIP.txt
#egrep do_deep /homed/ilogslave/log/server_31612.log |grep PeerIP| awk '{print $7}' | awk -F'[,|=]' '{print $7}'| sort -n | uniq -c | sort -n | awk '{if($1>6){print "/sbin/ipset add badip "$2}}' > badIP.txt
egrep do_deep /homed/ilogslave/log/server_*.log |grep PeerIP| awk '{print $7}' | awk -F'[,|=]' '{print $7}'| sort -n | uniq -c | sort -n | awk '{if($1>12 && $2 != ""){print "/sbin/ipset add badip "$2}}' > /r2/soft/badIP.txt
/sbin/ipset flush badip
while read line
do
	$line
done < /r2/soft/badIP.txt
