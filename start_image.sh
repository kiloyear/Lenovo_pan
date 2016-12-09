#!/bin/sh

selfpid=$$

box_dir=/opt/dragonball
. $box_dir/tools/include.sh
cfgtool=$box_dir/tools/jcfg.py 
boxdomain=$($cfgtool system/network/domain)

function pull_image()
{
     image_role=$1
     echo "what is role: $image_role"
     if [ $image_role == "portal" ] || [ $image_role == "registry" ]; then
       #skip portal and registry
       return;
     fi

     #get tag from registry
     image_all=${image_role}-all
     tag_info=$(curl -X GET "http://registry.lenovows.com:5000/v2/$image_all/tags/list")

     #check if successfully
     echo "$tag_info" | grep error
     if [ $? == 0 ] || [ -z $tag_info ]; then
       run_log "pull from registry failed for: $image_all"
       image_tag=$(docker images | grep $image_all | sort | awk '{print $2}')
     else
       run_log $tag_info
       image_tag=$($box_dir/tools/jsontool.py tags $tag_info | sort | tail -n 1)
     fi

     #no tag
     if [ -z $image_tag ]; then
       run_log "error: no such images: $image_all"
       exit 1
     fi
     run_log "pull registry.lenovows.com:5000/$image_all:$image_tag"
     docker   pull registry.lenovows.com:5000/$image_all:$image_tag
}

function check_dependency()
{
     run_log "check dependency..."
}

function stop_running_container()
{
     container_name=$1
     tmp_file="/tmp/${container_name}.${selfpid}"

     docker ps -a -f "name=$container_name" >$tmp_file
     while read line; do
       name="${line##* }"
       if [ x$name == x$container_name ]; then
        container_id="${line%% *}"
        run_log "stop running container: $container_id/$name"
        docker stop $container_id
        docker rm   $container_id
       fi
     done<$tmp_file
     /bin/rm -f $tmp_file
}


role_type=$1
role_name=$2
run_log "run $role_type, $role_name"

#to avoid duplicated name error
stop_running_container $role_name

pull_image $role_type

#make sure weave is running
$box_dir/tools/start_weave.sh

#image version
docker images | grep $role_type > /tmp/$role_type.ver
app_ver=$(cat /tmp/$role_type.ver | head -n 1 |awk '{print $1":"$2}')

#something special
port_map=
if [ $role_type == "haproxy" ]; then
     ap_port=$($cfgtool system/application/port 80)
     lk_port=$($cfgtool system/application/linkport 80)
     dc_port=$($cfgtool system/datacenter/port 10081)
     vd_port=$($cfgtool system/video/port 10095)
     ad_port=8000
     port_map="-p $ap_port:80 -p $dc_port:10081 -p $vd_port:10095 -p 8086:8086 -p $ad_port:8000"
     if [ $lk_port != $ap_port ]; then
       port_map=$port_map" -p $lk_port:80"
     fi
else
     port_map=$($cfgtool module/port/$role_name)
     #====open port for debug
     if [ $role_type == "queue" ]; then
       port_map="$port_map -p 5672:5672 -p 15672:15672"
     fi
fi
run_log "port_map: $port_map"

docker_ip=$($cfgtool module/ip/$role_name)
cmd_run="weave run $docker_ip/24 --name=$role_name -t -d"
retry_time="1 2"
for retry in $retry_time; do
     run_log "$cmd_run $port_map $dir_map $app_ver $role_type, times: $retry"
     $cmd_run $port_map $dir_map $app_ver $role_type

     sleep 1
     container_id=$(dtool id $role_name)
     if [ -z $container_id ]; then
       run_log "start $role_name failed, container id is empty, try again"
       sleep 1
     else
       break;
     fi
done

#notice, remove this first?
run_log "dns-add $container_id -h ${role_type}.${boxdomain}"
weave    dns-add $container_id -h ${role_type}.${boxdomain}

$box_dir/tools/consul.sh register $role_type $role_name
