#!/bin/sh

if [ $1 == get_user_used ]; then
     echo "user_num_used=0"
     exit 0
     #
     . /opt/dirmap/config/box.cfg
     PASS=lenovolabs
     HOST=$($portal_root/tools/jcfg.py device/iplist/database | head -n 1)
     /usr/bin/mysql -uroot -p$PASS -h $HOST iris_v40 -N -e "select CONCAT('user_num_used=',user_num_used) from iris_account_quota where account_id=1" >/tmp/used.txt 2>/dev/null
     cat /tmp/used.txt
fi
[root@localhost tools]# cat drun.sh 
#!/bin/sh

ROLE=$1
CMD=$2
if [ -z $1 ]; then
     exit 1
fi

container_id=
ROLES=$(/opt/dragonball/tools/jcfg.py device/roles)
for Role in $ROLES; do
     roletype=${Role##*::}
     rolename=${Role%%::*}
     if [ x$ROLE == x$roletype ]; then
       container_id=$(dtool id $rolename)
       break;
     fi
done

if [ -z $container_id ]; then
     exit 0
fi

if [ -z $CMD ]; then
     docker attach $container_id
else
     docker exec   $container_id $CMD
fi
