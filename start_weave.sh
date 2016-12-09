#!/bin/sh

box_dir="/opt/dragonball"
. $box_dir/tools/include.sh
cfgtool=$box_dir/tools/jcfg.py 

#====is it running?
wlog=/tmp/check_weave.log
docker ps | grep weaveexec >>$wlog 2>&1
if [ $? == 0 ]; then
     run_log "weaveexec is running"
     exit 0
else
     run_log "warning:! ! !   weaveexec is dead"
fi

run_log "weave151 is dead, launch it again"

#====load images
weave_path="$box_dir/src/thirdlib/weave_16"
docker images | grep 'weave ' >/dev/null
if [ $? == 0 ]; then
     run_log "weave151 is loaded"
else
     run_log "warning:    $weave_path/weave.151.tar    load weave first"
     docker load < $weave_path/weave.151.tar 
     run_log "launch weave.151: $?"

     docker load < $weave_path/weaveexec.151.tar
     run_log "launch weaveexec.151: $?"

     docker load < $weave_path/weavedb.latest.tar
fi

#====make server list
seedlist=
seedmine=
iplist=
declare -i I=1
ls /$box_dir/config | grep device_ |sort >/tmp/.devices.list
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

#=====launch weave
ip_range=$($cfgtool system/network/subnet)
if [ -z $ip_range ]; then
     ip_range="10.88.0.0/16"
fi

dns_name="--dns-domain=weave.local" # to avoid being confused with lenovows.com

run_log "run --name $seedmine --ipalloc-init seed=$seedlist --ipalloc-range $ip_range"
weave launch --name $seedmine --ipalloc-init seed=$seedlist --ipalloc-range $ip_range

if [ -z "$iplist" ]; then
     run_log "just me"
else
     run_log "weave connect $iplist"
     weave connect $iplist
fi
