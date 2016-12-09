#!/bin/bash

box_dir=/opt/dragonball
registry_ver="2.4.1"
registry_all="registry:2.4.1"
registry_tar="/opt/dragonball/registry/registry-2.4.1.tar"

function run_log()
{
     echo `date` "$@" | tee -a /tmp/run_image.log
}

#is it running ?
docker ps | grep $registry_all > /dev/null
if [ $? == 0 ]; then
     run_log "registry is running"
     exit 0
fi

#is it loaded?
docker images | grep registry | grep $registry_ver > /dev/null
if [ $? == 0 ]; then
     run_log "registry is already loaded"
else
     run_log "load $registry_tar"
     docker load < $registry_tar
fi

run_log "run $registry_all"
if [ -z $1 ]; then
     data_path=/data
else
     data_path=$1
fi

registry_dir=$data_path/ball/registry
registry_tmp=$data_path/ball/tmp/registry

mkdir -p $registry_dir
mkdir -p $registry_tmp

docker run -ti -d --restart=always -e REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY=/var/lib/registry \
-v $registry_dir:/var/lib/registry \
-v $registry_tmp:/tmp/registry \
-p 5000:5000 $registry_all
