#!/bin/sh

box_dir=/opt/dragonball
selfpid=$$
container_name=$1
echo "stop $container_name"

function stop_dead()
{
     all_list=/tmp/all_list.$$
     ali_list=/tmp/ali_list.$$
     docker ps -aq > $all_list
     docker ps -q  > $ali_list
     while read line; do
       cat $ali_list | grep $line
       if [ $? != 0 ]; then
        docker stop $line
        docker rm   $line
       fi
     done<$all_list
}

function stop_container()
{
     tmp_file="/tmp/${container_name}.${selfpid}"
     docker ps -a -f "name=$container_name" >$tmp_file
     while read line; do
       name="${line##* }"
       if [ x$name == x$container_name ]; then
        $box_dir/tools/consul.sh unregister $name
        container_id="${line%% *}"
        echo "stop  $container_id"
        docker stop $container_id
        docker rm   $container_id
       fi
     done<$tmp_file
     /bin/rm -f $tmp_file
}

function stop_all()
{
     $box_dir/tools/consul.sh unregister all
     container_ids=$(docker ps -aq)
     for cid in $container_ids; do
       #skip portal
       docker ps | grep $cid | grep portal
       if [ $? == 0 ]; then
        continue;
       fi
       #skip weave
       docker ps | grep $cid | grep weaveworks
       if [ $? == 0 ]; then
        continue;
       fi
       #skip registry
       docker ps | grep $cid | grep "registry:2.4.1"
       if [ $? == 0 ]; then
        continue;
       fi
       docker stop $cid
       docker rm   $cid
     done

     #maybe devices changed, weave should reconnect
     docker ps | grep weave
     if [ $? == 0 ]; then
       weave reset
     fi
}

if   [ $container_name == "all" ]; then
     stop_all
elif [ $container_name == "dead" ]; then
     stop_dead
else
     stop_container
fi
