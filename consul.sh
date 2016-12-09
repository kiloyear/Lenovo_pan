#!/bin/sh

box_dir="/opt/dragonball"
box_cfg="/opt/dragonball/config/box.cfg"

. $box_cfg
box_map=$box_data

function run_log()
{
        echo `date` "$@" | tee -a /tmp/run_image.log
}

function start()
{
     #for port 8500
     iptables -F

     run_log "start consul"
     mkdir -p /etc/consul.d
     server_mode=
     if [ $portal_ip == $local_ip ]; then
       server_mode="-server -bootstrap-expect 1" 
     fi
     run_log "consul agent $server_mode -node $local_ip -client=0.0.0.0 -data-dir /var/lib/consul -config-dir /etc/consul.d -join $portal_ip"
     #nohup /usr/local/bin/consul agent $server_mode -node $local_ip -client=0.0.0.0 -data-dir /var/lib/consul -config-dir /etc/consul.d -join $portal_ip >>/var/log/consul.log &
     nohup /usr/local/bin/consul agent -node $local_ip -client=0.0.0.0 -data-dir /var/lib/consul -config-dir /etc/consul.d >>/var/log/consul.log &
}

function stop()
{
     run_log "stop consul"
     consul_pid=$(ps -ef | grep consul | grep "consul agent" |grep -v grep |awk '{print $2}')
     if [ -z $consul_pid ]; then
       run_log "no consul pid"
     else
       kill $consul_pid
     fi
}

function status()
{
     run_log "status consul"
     consul_pid=$(ps -ef | grep consul | grep "consul agent" |grep -v grep |awk '{print $2}')

     if [ -z $consul_pid ]; then
       exit 1
     fi
     exit 0
}

function keep_running()
{
     curl -X GET "http://127.0.0.1:8500/v1/agent/services" >> /tmp/consul.run 2>&1
     if [ $? == 0 ]; then
       run_log "consul is running"
     else
       run_log "consul is not running. start it"
       start
     fi
}

function register()
{
     role_type=$1
     role_name=$2
     ID=${role_name}
     run_log "register service $role_name"

     mkdir -p $box_map/consul
     check_sh="$box_map/consul/check_${role_name}"

     /bin/cp -f "$box_dir/tools/services/consul/check_service.sh" ${check_sh}

     post_data="{\"Name\": \"$ID\", \"ID\":\"$ID\", \"Check\":{\"Script\":\"${check_sh}\", \"Interval\":\"5s\"}}"
     curl -X PUT -d "$post_data" "http://127.0.0.1:8500/v1/agent/service/register"
}

function unregister()
{
     run_log "unregister service: $1"
     role_name=$1
     if [ $role_name == "all" ]; then
       ALL=$(ls $box_map/consul/check_*)
       for item in $ALL; do
        checksh=$(basename $item)
        rolename=${checksh##*_}
        curl -X PUT http://127.0.0.1:8500/v1/agent/service/deregister/$rolename
        /bin/rm -f $item
       done
     else
       check_sh="$box_map/consul/check_${role_name}"
       /bin/rm -f $check_sh
       curl -X PUT http://127.0.0.1:8500/v1/agent/service/deregister/$role_name
     fi
}

function try_lock()
{
     lock_name=$1
     . /opt/dragonball/config/box.cfg
     run_log "curl -X PUT -d {\"name\":\"$lock_name\",\"behavior\":\"delete\",\"ttl\":\"1000s\"} http://$portal_ip:8500/v1/session/create"
     curl -X PUT -d "{\"name\":\"$lock_name\",\"behavior\":\"delete\",\"ttl\":\"1000s\"}" "http://$portal_ip:8500/v1/session/create"
}

case $1 in

     start)
       start
     ;;

     stop)
       stop
     ;;

     status)
       status
     ;;

     keep_running)
       keep_running
     ;;

     restart)
       stop; sleep 1; start
     ;;

     register)
       register $2 $3
     ;;

     unregister)
       unregister $2
     ;;

     trylock)
       try_lock $2
     ;;

     *)
       echo "not support yet"
     ;;
esac
