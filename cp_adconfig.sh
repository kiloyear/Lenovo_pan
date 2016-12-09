#!/bin/sh

# use real path, not link path like /opt/dragonball
. /opt/dragonball/config/box.cfg
box_dir=$portal_root

$box_dir/config/jcfg.py device/iplist/ad  > /tmp/ad.list
while read line; do
     if [ $line == $local_ip ]; then
       continue;
     fi

     target_host=$line
     # read user/pass from device files
     login_user=$($box_dir/tools/jcfg.py device/user     $target_host)
     login_pass=$($box_dir/tools/jcfg.py device/password $target_host)
     login_port=$($box_dir/tools/jcfg.py device/port     $target_host)
     parameters="$target_host $login_port $login_pass"
     $box_dir/tools/scp.sh /opt/ad/app/config  $parameters

done</tmp/ad.list
