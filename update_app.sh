#!/bin/sh

. /opt/dragonball/tools/include.sh
box_root=$portal_root
app_root=$portal_root/src/application
cfg_tool=$box_root/tools/jcfg.py
resin_sh=/opt/srv/resin/bin/resin.sh
app_path_in=/opt/dirmap/src/application
box_path_in=/opt/srv/resin/webapps/box.war

function usage()
{
     echo "Usage:"
     echo "     $0 <path of box.war>"
     echo "     $0 <source file> <target path in app container>"
     exit 1
}

function update_box()
{
     box_new=$1
     box_cur=$app_root/box.war

     cur_date=$(date +%y%m%d%H%M%S)
     mv $box_cur ${box_cur}.${cur_date}
     cp $box_new $box_cur

     echo "clear /root/.ssh/known_hosts"
     /bin/rm -f /root/.ssh/known_hosts

     echo "update file in every servers"
     $cfg_tool device/iplist/all |sort|uniq >/tmp/server.all
     while read line; do
       target_host=$line
       if [ $local_ip == $target_host ]; then
        echo "skip myself"
        continue
       fi

       echo "-----------------------update file in $target_host-----------------------"
       login_pass=$($cfg_tool device/password lenovolabs $target_host)
       login_port=$($cfg_tool device/port     22         $target_host)
       $box_root/tools/scp.sh $box_cur $target_host $login_port $login_pass

     done</tmp/server.all

     echo "update box.war in container, will restart resin"
     $cfg_tool device/iplist/application >/tmp/applist.up
     while read line; do
       target_host=$line
       login_pass=lenovolabs
       login_port=11022
       echo "-----------------------update continer for $target_host-----------------------"
       cmd="$resin_sh stop; /bin/cp -f $app_path_in/box.war $box_path_in; $resin_sh start"
       $box_root/tools/remote_cmd.sh $target_host $login_port $login_pass "$cmd"
     done</tmp/applist.up

     echo "done."
}


function update_app_files()
{
     file_new=$1
     file_dst=$2
     file_tmp=${file_dst#/opt/}
     file_in_src=$app_root/$file_tmp
     file_in_app=$app_path_in/$file_tmp
     echo "$file_in_src"
     echo "$file_in_app"

     echo "/bin/cp -f $file_new $file_in_src"
     /bin/cp -f $file_new $file_in_src

     echo "clear /root/.ssh/known_hosts"
     /bin/rm -f /root/.ssh/known_hosts

     echo "update file in every servers"
     $cfg_tool device/iplist/all |sort|uniq >/tmp/server.all
     while read line; do
       target_host=$line
       if [ $local_ip == $target_host ]; then
        echo "skip myself"
        continue
       fi

       echo "-----------------------update file in $target_host-----------------------"
       login_pass=$($cfg_tool device/password lenovolabs $target_host)
       login_port=$($cfg_tool device/port     22         $target_host)
       $box_root/tools/scp.sh $file_in_src $target_host $login_port $login_pass

     done</tmp/server.all

     echo "update $file_dst in container"
     $cfg_tool device/iplist/application >/tmp/applist.up
     while read line; do
       target_host=$line
       echo "-----------------------update continer for $target_host-----------------------"
       login_pass=lenovolabs
       login_port=11022
       cmd="/bin/cp -f $file_in_app $file_dst"
       $box_root/tools/remote_cmd.sh $target_host $login_port $login_pass "$cmd"

     done</tmp/applist.up

     echo "done."
}


#print help
if [ -z $1 ]; then
     usage
fi

#argments
src_path=$1
dst_path=$2

#something special for box.war
file_name=$(basename $src_path)
if [ $file_name == "box.war" ]; then
     update_box $src_path
     exit 0
fi

#other files, actually, it should be something like /opt/webapps/xxxxxx
if [ -z $dst_path ]; then
     echo "need dst path"
     exit 1
fi
update_app_files $src_path $dst_path
