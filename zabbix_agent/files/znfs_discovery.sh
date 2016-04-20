#!/usr/bin/env bash

mountpoints=$(grep nfs /etc/fstab |grep -v ^# |awk '{print $2}')

echo -n '{"data":['
for mount in $mountpoints; do echo -n "{\"{#NFSMOUNT}\":\"$mount\"},"; done |sed -e 's:\},$:\}:'
echo -n ']}'

