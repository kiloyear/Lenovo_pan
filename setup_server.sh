#!/bin/sh

my_ip=$1
box_link="/opt/dragonball"
box_data="/data/ball/dirmap"
box_root=

function get_box_root()
{
     sh_name=$1
     first_char=${sh_name:0:1}

     #Example: /opt/DragonBall<tag>/tools/setup_server.sh 192.168.0.3
     if [ $first_char == "/" ]; then
       #run_log "run shell from absolute path"
       box_root=${sh_name%%/tools*}
     else
       #run_log "run shell from relative path"
       cur_dir=$(pwd)
       apath=${cur_dir}/${sh_name}
       box_root=${apath%%/tools*}
     fi

     #run_log "box root dir is $box_root"
}
get_box_root $0

#duplicated function with include.sh...
function run_log()
{
        echo `date` "$@" | tee -a /tmp/run_image.log
}

function ugly_exit()
{
     selfpid=$$
     selfname=$(basename $0)

     parent_cmd=($(ps -ef | grep $selfpid | grep $selfname | grep -v grep))
        parent_pid=${parent_cmd[2]}

        # sshd with notty, this should be a remote call from portal server
        ps -ef | grep $parent_pid | grep "sshd: root@notty"
        if [ $? == 0 ]; then
                kill -9 $parent_pid
        fi
}

cfg_path=$box_root/config
bin_path=$box_root/tools/bin
package_path=$box_root/src/thirdlib

function create_box_cfg()
{
     /bin/cp -f $cfg_path/portal.cfg $cfg_path/box.cfg
     echo "local_ip=$my_ip" >> $cfg_path/box.cfg
     echo "box_data=$box_data" >> $cfg_path/box.cfg

     #set a flag that this server has been setup.
     /bin/cp -f $cfg_path/box.cfg $box_root/box.ins
}

function create_box_data()
{
     #link to root
     /bin/rm -rf $box_link
     ln -s $box_root $box_link

     #put mysql data, cell or something here
     mkdir   -p $box_data

     #copy one for using in container 
     /bin/cp -f $box_root/tools/jcfg.py $cfg_path

     #put ssl cert  here
        mkdir   -p $box_data/haproxy
}

function setup_environment()
{
     run_log "close firewall..."
     iptables -F
     service firewalld stop

     #we could remove this
     mkdir -p /var/lib/docker

     run_log "install expect..."
     tar zxf $package_path/expect.tar.gz -C /
     tar zxf $package_path/tcl.tar.gz -C /

     run_log "install ntpdate..."
     tar zxf $package_path/ntpdate.tar.gz -C /

     run_log "set portal hosts..."
     . $box_root/config/portal.cfg
     /bin/cp -f /etc/hosts /tmp/thosts
     sed -i "/registry.lenovows.com/d" /tmp/thosts
     echo "$portal_ip registry.lenovows.com" >> /tmp/thosts
     /bin/cp -f /tmp/thosts /etc/hosts

     ntpdate $portal_ip
     echo "*/5 * * * * root ntpdate $portal_ip" >>/etc/crontab

     run_log "install binary files..."
     chmod a+x  $box_root/tools/bin/*
     /bin/cp -f $box_root/tools/bin/* /usr/local/bin

     run_log "set auto start..."
     chmod a+x  $box_root/tools/boxcss.service
     /bin/cp -f $box_root/tools/boxcss.service /etc/init.d/boxcss
     chkconfig --level 345 boxcss on

     run_log "start box services..."
     dtool start_docker

     run_log "setup environment completed."
}

function clear_env()
{
     run_log "clear env...ok"
     /bin/rm -rf /var/lib/consul
     /bin/rm -rf /var/lib/docker

     /bin/cp -f /ertc/crontab /etc/crontab.before
}

function extract_src()
{
     run_log "extract src"
     ls $box_root/src | grep application
     if [ $? != 0 ]; then
       cd $box_root
       tar zxf src.tar.gz
       cd -
     fi
}

function setup_consul()
{
     run_log "cp consul monitor scripts"

     /bin/cp -f $box_root/tools/services/consul/check* /usr/local/bin
     /bin/cp -f $box_root/tools/services/consul/systemHealth.json /etc/consul.d

     grep "crontab_flag" /etc/crontab
     if [ $? == 0 ]; then
       run_log "consul is already in crontab"
     else
       #not a good place...
       echo "#crontab_flag" >> /etc/crontab
       echo "* * * * * root $box_root/tools/box_monitor.sh" >>/etc/crontab
       echo "0 0 * * * root $box_root/tools/clean_log.sh /var/log/docker.log" >>/etc/crontab
     fi
}

function install_rpms()
{
     run_log "install keepalived"
     rpm -ih $package_path/lm_sensors-libs-3.3.4-11.el7.x86_64.rpm --nodeps
     rpm -ih $package_path/net-snmp-agent-libs-5.7.2-24.el7_2.1.x86_64.rpm --nodeps
     rpm -ih $package_path/net-snmp-libs-5.7.2-24.el7_2.1.x86_64.rpm --nodeps
     rpm -ih $package_path/keepalived-1.2.13-7.el7.x86_64.rpm --nodeps
}

#important....
#because setup_server.sh might be called many times...
if [ -f $box_root/box.ins ]; then
     run_log "refresh config"

     create_box_cfg

     run_log "this server has been already setup"

     ugly_exit

     exit 0
fi

clear_env

create_box_cfg

create_box_data

extract_src

install_rpms

setup_consul

setup_environment

run_log "setup server completed"

ugly_exit
