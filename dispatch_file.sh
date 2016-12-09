#!/bin/sh

# use real path, not link path like /opt/dragonball
. /opt/dragonball/config/box.cfg
box_dir=$portal_root

$box_dir/config/jcfg.py device/iplist/ad  > /tmp/ad.list
while read line; do
     if [ $line == $local_ip ]; then
       continue;
     fi

     target_host=$line
     # read user/pass from device files
     login_user=$($box_dir/tools/jcfg.py device/user     $target_host)
     login_pass=$($box_dir/tools/jcfg.py device/password $target_host)
     login_port=$($box_dir/tools/jcfg.py device/port     $target_host)
     parameters="$target_host $login_port $login_pass"
     $box_dir/tools/scp.sh /opt/ad/app/config  $parameters

done</tmp/ad.list
[root@localhost tools]# cat dispatch_file.sh 
#!/bin/sh

. /opt/dragonball/tools/include.sh

box_root=$portal_root

function usage()
{
cat >&2 <<EOF
Usage:
     Given a absolute path, scp it to all servers automatically:
       update_src /opt/test/a.txt

     The command below will sync /opt/dragonball/src to all servers, be careful to use this:
       update_src all
EOF
}

function cp_all()
{
     target_host=$1
     run_log "dispatch to $target_host"

     login_user=$($box_root/tools/jcfg.py device/user     root       $target_host)
     login_pass=$($box_root/tools/jcfg.py device/password lenovolabs $target_host)
     login_port=$($box_root/tools/jcfg.py device/port     22         $target_host)
     parameters="$target_host $login_port $login_pass"

     $box_root/tools/scp.sh $box_root/patch  $parameters

     $box_root/tools/scp.sh $box_root/tools  $parameters

     $box_root/tools/scp.sh $box_root/src.tar.gz  $parameters
     $box_root/tools/remote_cmd.sh $parameters "tar zxf $box_root/src.tar.gz -C $box_root"
}

function cp_files()
{
     files=$1
     target_host=$2
     run_log "dispatch ($files) to $target_host"

     login_user=$($box_root/tools/jcfg.py device/user     root       $target_host)
     login_pass=$($box_root/tools/jcfg.py device/password lenovolabs $target_host)
     login_port=$($box_root/tools/jcfg.py device/port     22         $target_host)
     parameters="$target_host $login_port $login_pass"

     if [ -d $files ]; then
       $box_root/tools/remote_cmd.sh $parameters "/bin/rm -rf $files"
     fi
     $box_root/tools/scp.sh $files $parameters
}

if [ -z $1 ]; then
     usage
fi
if [ -z $2 ]; then
     $box_root/tools/jcfg.py device/iplist/all |sort|uniq >/tmp/uhost.txt
else
     echo "$dsthost" >/tmp/uhost.txt
fi

files=$1
while read line; do
     if [ $local_ip == $line ]; then
       echo "skip self: $line"
       continue
     fi
     echo "update $line"
     if [ $files == "all" ]; then
       cp_all $line
     else
       cp_files $files $line
     fi
done</tmp/uhost.txt
