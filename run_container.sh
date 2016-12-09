#!/bin/sh

selfpid=$$
box_dir="/opt/dragonball"
box_cfg="$box_dir/config/box.cfg"
. $box_cfg

function run_log()
{
        echo `date` "$@" | tee -a /tmp/run_image.log
}

function check_dns()
{
     roletype=$1
     rolename=$2
     weave status dns | grep $rolename 
     if [ $? == 0 ]; then
       run_log "add dns $rolename ok"
     else
       run_log "ERROR: add dns failed, run again"
       $box_dir/tools/start_image.sh $roletype $rolename
     fi
}

function single_running()
{
     exe_name=$(basename $0)
     pid_file=/opt/${exe_name}.pid
     if [ -f $pid_file ]; then
       cat $pid_file
             lastpid=$(cat $pid_file)
       run_log "last pid: $lastpid"
             ps -ef | grep $exe_name | grep $lastpid >/dev/null
             if [ $? == 0 ]; then
                     run_log "$exe_name is running, I quit."
                     exit 0
             fi
     else
       run_log "create $pid_file"
     fi
     echo $$ > $pid_file
}

################################### what is going to run? ######################################
role_name=$1
run_log "start $role_name"

#only one instance
single_running

#clear all dead container
$box_dir/tools/stop_container.sh dead

#make sure consul is already started
$box_dir/tools/consul.sh restart

$box_dir/tools/start_weave.sh

if [ $role_name == "portal" ]; then
     $box_dir/tools/start_portal.sh

elif [ $role_name == "all" ]; then
     ROLES=$($box_dir/tools/jcfg.py device/roles)
     run_log "start all services: $ROLES"

     $box_dir/tools/start_portal.sh

     for Role in $ROLES; do
       #run all roles:"application_1::application database_1::database "
       roletype=${Role##*::}
       rolename=${Role%%::*}
       run_log $roletype, $rolename

       $box_dir/tools/start_image.sh $roletype $rolename
       check_dns $roletype $rolename
       sleep 1
     done

else
     role_type=$($box_dir/tools/jcfg.py device/roletype/$role_name)
     run_log "start : $role_name/$role_type"
     if [ -z $role_type ]; then
       run_log "there is no such role for $role_name"
       exit 1
     fi

     $box_dir/tools/start_image.sh $role_type $role_name
     check_dns $role_type $role_name
fi
