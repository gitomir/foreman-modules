#!/bin/bash

 

# Simple rsync / no loadbalancing check

# Every front is synched !!

# Check for script if it`s run with sudo or not:


if [[ $EUID -ne 0 ]]; then
   echo "This script need to be run with sudo" 
   exit 1
fi 

ROOT="/data"

HOSTNAME=`hostname`

if [ $HOSTNAME != "aws-frontend-0" ]; then
        echo "$HOSTNAME is not master!"
        exit 0 
fi

zabbix_host="10.10.0.40"
zabbix_port="10051"
#Hostname will be transformed with uppercases.

zabbix_sender="/usr/bin/zabbix_sender -z $zabbix_host -p $zabbix_port -s ${HOSTNAME^^} "

echo "$HOSTNAME is master!"

#POOL="axs-frontend-1 axs-frontend-2 axs-frontend-3 axs-frontend-4 aws-frontend-0 aws-frontend-1 aws-frontend-2"
POOL="aws-frontend-1 aws-frontend-2 aws-frontend-3"

LOCKFILE="/tmp/mass_rsync.lock"

#timestamp function
timestamp() {
        date +"%T"
}


if [ -f $LOCKFILE ]; then

echo "$(timestamp) Rsync is running ($LOCKFILE exists) ..."

ls -l $LOCKFILE

echo "date +%c"

exit 0

fi



touch $LOCKFILE

chown :axsmarine $LOCKFILE

chmod g+w $LOCKFILE



for HOST in $POOL; do

        echo "$(timestamp) rsync files to $HOST"

        /usr/bin/rsync --delete -W --stats --exclude-from=/usr/local/tools/exclude.rsync -avz -e ssh $ROOT/static $ROOT/a* $ROOT/data_snp $ROOT/ext* $ROOT/import_liner $ROOT/include* $ROOT/soap $ROOT/lib $ROOT/www* $ROOT/topgallant $ROOT/mobile $ROOT/datamanager $ROOT/beta $ROOT/crm.axsmarine.com $ROOT/oldendorff $ROOT/axstankerv4.axsmarine.com $ROOT/monit.axsmarine.com $ROOT/tanker-scripts $ROOT/dry-scripts root@$HOST:$ROOT/

	Exit_Code=`echo $?`
        Output=`$zabbix_sender -k rsync[exit,code] -o $Exit_Code`

	echo "$(timestamp) rsync ok for $HOST"

        echo

done



rm -f $LOCKFILE

#EOF
