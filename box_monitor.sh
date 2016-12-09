#!/bin/sh
. /opt/dragonball/tools/include.sh
. /$box_dir/tools/services/common.sh

export PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin

function check_log()
{
        echo `date` "$@" | tee -a /tmp/check_box.log
}

function check_consul()
{
     curl -X GET "http://127.0.0.1:8500/v1/agent/checks" >/tmp/consul.check
     if [ $? != 0 ]; then
       check_log "consul is not running. start it"
       $box_dir/tools/consul.sh start
       return;
     fi

     cat /tmp/consul.check | grep "dtool: command not found" > /dev/null
     if [ $? == 0 ]; then
       check_log "consul status is error, restart it"
       $box_dir/tools/consul.sh restart
       return;
     fi

     echo "consul is ok" >> /tmp/check.log
}

function check_images()
{
     docker_status=$(/usr/local/bin/dtool status)
     dtool status >> /tmp/check.log
     check_log "docker status: $docker_status"

     if [ -z $docker_status ] || [ $docker_status != running ]; then
       check_log "docker is not running"
       return
     fi

     ps -ef | grep run_container | grep -v grep >> /tmp/check.log
     if [ $? == 0 ]; then
       check_log "run container is running"
       return
     fi

     ALL=$(ls $box_map/consul/check_*)
     docker ps > /tmp/docker.ps
     for item in $ALL; do
       checksh=$(basename $item)
       rolename=${checksh##*_}

       check_log "check $rolename"
       cat /tmp/docker.ps | grep $rolename >> /tmp/check.log
       if [ $? == 0 ]; then
        check_log "$rolename is ok"
        continue;
       fi
       check_log "warning: recheck $rolename" >> /tmp/check.log
       docker ps > /tmp/docker.ps
       cat /tmp/docker.ps | grep $rolename >> /tmp/check.log
       if [ $? == 0 ]; then
        check_log "$rolename is ok"
       else
        check_log "$rolename is disappeared, run it again"
        $box_dir/tools/run_container.sh $rolename
       fi
     done
}

function check_ad()
{
     cfgnew=/data/ball/dirmap/ad/newcfg
     cfgdir=/data/ball/dirmap/ad/config
     if [ -f $cfgnew ]; then
       echo "something new" >> /tmp/check_ad.log
       ls $cfgdir/* >/tmp/newcfg.txt
       while read line;do
        /opt/dragonball/tools/dispatch_file.sh $line
       done</tmp/newcfg.txt
       /bin/rm -f $cfgnew
     fi
}

single_running

check_consul

check_ad

#check_images
