#!/bin/sh

. /opt/dragonball/tools/include.sh

# use real path, not link path like /opt/dragonball
box_root=$portal_root

# copy files to this host
target_host=$1
run_log "dispatch to $target_host"

# read user/pass from device files
login_user=$($box_root/tools/jcfg.py device/user     root       $target_host)
login_pass=$($box_root/tools/jcfg.py device/password lenovolabs $target_host)
login_port=$($box_root/tools/jcfg.py device/port     22         $target_host)
parameters="$target_host $login_port $login_pass"

#make sure the folder is ready
#$box_root/tools/remote_cmd.sh $parameters "mkdir -p $box_root"

run_log "/opt/dragonball/tools/scp.sh $box_root/patch  $parameters"
/opt/dragonball/tools/scp.sh $box_root/patch  $parameters

#config, remove old first
run_log "remove and copy $box_root/config $parameters"
$box_root/tools/remote_cmd.sh $parameters "/bin/rm -fr $box_root/config" 
/opt/dragonball/tools/scp.sh $box_root/config $parameters

$box_root/tools/remote_cmd.sh $parameters "ls $box_root"  | grep tools
if [ $? == 0 ]; then
     run_log "tools exists, skip copying"
else
     run_log "/opt/dragonball/tools/scp.sh $box_root/tools  $parameters"
     $box_root/tools/scp.sh $box_root/tools  $parameters
fi

$box_root/tools/remote_cmd.sh $parameters "ls $box_root"  | grep src.tar.gz
if [ $? == 0 ]; then
     run_log "remote has src.tar.gz, skip copying"
else
     cd $box_root
     if [ -f src.tar.gz ]; then
       run_log "src.tar.gz exists"
     else
       tar zcf src.tar.gz src
     fi
     run_log "/opt/dragonball/tools/scp.sh $box_root/src.tar.gz   $parameters"
     $box_root/tools/scp.sh $box_root/src.tar.gz  $parameters
fi

run_log "finished dispatching to $target_host"
ugly_exit
