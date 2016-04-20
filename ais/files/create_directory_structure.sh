#!/bin/bash

declare -a dir_struct=(
       '/data/2/VTHistoryInserted'\
       '/data/2/www/ais'\
       '/data/2/www/crond'\
       '/data/2/www/store'\
       '/data/2/www/WWW'\
       '/data/2/share/logs/DryExports'\
       '/data/2/share/logs/LinerExports'\
       '/data/2/share/logs/OffshoreExports'\
       '/data/2/share/logs/Positions'\
       '/data/2/share/logs/TankerExports'\
       '/data/2/share/logsInf/DryExports'\
       '/data/2/share/logsInf/LinerExports'\
       '/data/2/share/logsInf/OffshoreExports'\
       '/data/2/share/logsInf/TankerExports'\
       '/data/2/share/logs_archive'\
       '/data/3/store_archive'\
       '/data/3/ptip_archive'\
);

for dir in "${dir_struct[@]}"
do
        echo $dir;
        if [[ ! -e $dir ]]; then
                install -d -o ais -g ais -m 775 $dir
        fi
done;


chown -R ais:ais /data/2
chown -R ais:ais /data/3
chmod 775 $(find /data/2 -type d)
chmod 775 $(find /data/3 -type d)
