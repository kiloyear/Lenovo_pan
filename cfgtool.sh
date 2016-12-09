#!/bin/sh

selfpid=$$
box_dir="/opt/dragonball"
box_cfg="$box_dir/config/box.cfg"

. $box_cfg
box_map=$box_data

function db_members()
{
     #check server list
     ls /$box_dir/config | grep device_ |sort >/tmp/.devices.list
     declare -i I=1
     seedlist=
     seedmine=
     iplist=
     while read line; do
       dip=${line##*device_}
       if [ $dip == $local_ip ]; then
        seedmine=::$I
       else
        iplist="$iplist $dip"
       fi
       if [ -z $seedlist ]; then
        seedlist=::1
       else
        seedlist="$seedlist,::$I"
       fi
       I=$I+1
     done</tmp/.devices.list
}
