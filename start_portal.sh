#!/bin/sh

. /opt/dragonball/tools/include.sh

selfpid=$$
#sometimes, a container died, it was not shown by 'docker ps', we can catch it using 'docker ps -a'
function stop_dead_container()
{
     container_name=$1
     tmp_file="/tmp/${container_name}.${selfpid}"

     docker ps -a -f "name=$container_name" >$tmp_file
     while read line; do
       name="${line##* }"
       if [ x$name == x$container_name ]; then
        container_id="${line%% *}"
        docker ps | grep $container_id
        if [ $? == 0 ]; then
                continue;
        fi
        run_log "stop dead container: $container_id/$name"
        docker stop $container_id
        docker rm   $container_id
       fi
     done<$tmp_file
     /bin/rm -f $tmp_file
}



if [ x$portal_ip != x$local_ip ]; then
     run_log "this is not a portal server"
     exit 1
fi

#start registry with portal...
sh $box_dir/tools/start_registry.sh

docker ps | grep portal > /dev/null
if [ $? == 0 ]; then
     run_log "portal is running"
     exit 0
fi

stop_dead_container portal

docker images | grep portal >/dev/null
if [ $? == 0 ]; then
     run_log "portal is already loaded"
else
     run_log "$box_dir/tools/import_images.sh $box_dir portal"
     $box_dir/tools/import_images.sh $box_dir portal 
fi

cmd_run="docker run -ti -d -p 10085:10085 -p 11021:22  $dir_map -v $portal_root:$portal_root"
app_ver=`docker images | grep portal | awk '{print $1":"$2}'`

run_log "$cmd_run $app_ver portal"
$cmd_run $app_ver portal
