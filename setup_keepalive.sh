#!/bin/sh

echo "warning: is another keepalived is running, stop it first"
echo "warning: is the server the haproxy server? [yes]"
read line
if [ x$line == xyes ]; then
     echo "ok, continue"
else
     exit 0
fi

role=$1
vip=$2
ninf=$3
if [ -z $vip ]; then
     echo "$0 <master/backup> <vip> [interface]"
     echo "$0 master 192.168.1.100"
     echo "$0 backup 192.168.1.100"
     exit 1
fi

#detect interface by local_ip
. /opt/dragonball/config/box.cfg
ipinfo=$(ip a | grep $local_ip)
if [ -z $ninf ]; then
     netinf=${ipinfo##* }
else
     netinf=$ninf
fi
echo "we use this interface: $netinf"
if [ -z $netinf ]; then
     echo "no interface"
     exit 1
fi

#ip with netmask
ipmask=$(echo "$ipinfo" | awk '{print $2}')
netmask=$(basename $ipmask)
echo "ip with mask: $vip/$netmask"

#virtual_router_id
vrid=$(echo $vip |awk -F . '{print $4}')

#generate config
tmpfile=/tmp/keepalived.conf
/bin/cp -f /opt/dragonball/src/keepalived/keepalived_${role}.conf $tmpfile
sed -i "s/eth0/$netinf/g" $tmpfile
sed -i "s/vip_to_be_replace/$vip\/$netmask/g" $tmpfile
sed -i "s/vrid_to_be_replace/$vrid/g" $tmpfile

/bin/cp -f $tmpfile /etc/keepalived/

#start now
keepalived -D -f /etc/keepalived/keepalived.conf

#auto start
chkconfig keepalived on

#broadcast vip
echo "broadcast $vip"
arping -b -A -c 10 -I $netinf $vip

#ifconfig eth0:1 192.168.0.1 netmask 255.255.255.0
#ip addr del 192.168.0.1 dev eth0
