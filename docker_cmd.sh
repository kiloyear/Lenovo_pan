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
