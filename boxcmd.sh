#!/bin/sh

SidFile="/tmp/sid.txt"

IRIS_URL="http://$1/v2"
FILE_URL="http://$1:10081/v2"
IRIS_GET="curl -X GET ${IRIS_URL}"
FILE_GET="curl -X GET ${FILE_URL}"
IRIS_POST="curl -X POST ${IRIS_URL}"
FILE_POST="curl -X POST ${FILE_URL}"

echo $IRIS_URL
ssid=
if [ -f $SidFile ]; then
     ssid=`cat $SidFile`
fi
COOKIE="-k --cookie X-LENOVO-SESS-ID=${ssid}"

function get_session()
{
     /bin/rm -f $SidFile
     cat /tmp/login.txt |grep -Eo "X-LENOVO-SESS-ID\":\"[a-z0-9]+" |awk -F "\"" '{print $3}' > $SidFile

     ssid=`cat $SidFile`
     Succ=0
     if [ -z $ssid ]; then
       cat /tmp/login.txt
       Succ=1
     else
       cat $SidFile
       Succ=0
     fi
     exit $Succ
}

function process_cmd()
{
case "$1" in
     login)
       PASSWD=$3
       /bin/rm -f $Cookie
       /bin/rm -f /tmp/login.txt
       curl -X POST "${IRIS_URL}/user/login" -k -d "user_slug=${2}&password=${PASSWD}" > /tmp/login.txt 2>&1
       get_session
       ;;

     create_folder)
       curl -X POST ${IRIS_URL}"/fileops/create_folder/databox/${2}" ${COOKIE}  -d "path_type=self&from=" -v -i >/tmp/create_folder.txt
       ;;
 
     cdelivery)
       curl -X POST "${IRIS_URL}/delivery/create/databox$2" ${COOKIE} -d"mode=wp&password=&path_type=self"  -v -i
       ;;

     deletef)
       curl -X POST ${IRIS_URL}"/fileops/delete/databox$2" ${COOKIE}  -d "path_type=self&from=" -v -i
       ;;

     move)
       curl -X POST ${IRIS_URL}"/fileops/move" ${COOKIE} -d "root=databox&from_path=$2&from_path_type=self&from_from=&to_path=$3&to_path_type=self&to_from=" -v -i
       ;;

     inject_file)
       Bytes=$3
       curl -X POST ${IRIS_URL}"/fileops/inject_file" ${COOKIE}  -d "path_type=self&from=&seed=seedtesttest&root=databox&path=$2&bytes=$Bytes" -v -i
       ;;

     upload)
       Header="-H content-type:application/x-www-form-urlencoded"
       curl -X POST ${FILE_URL}"/files/databox$2?path_type=self" $COOKIE $Header -d "path_type=self&from=&neid=0" -v -T $3 
       ;;

     meta)
       curl -X GET ${IRIS_URL}"/metadata/databox$2?path_type=self" $COOKIE -v 
       ;;

     download)
       curl -X GET ${FILE_URL}"/files/databox$2?rev=$3&neid=$4?path_type=self" $COOKIE -v > /tmp/dw.txt 
       ;;

     revision)
       curl -X GET ${IRIS_URL}"/revisions/databox$2?path_type=self&from=" $COOKIE -v -i
       ;;

     create)
       curl -X POST ${IRIS_URL}"/user/create" ${COOKIE} -d "user_slug=${2}&user_name=${3}&password=${4}&password_changeable=true&quota=${5}&from_domain_account=false" -v -i
       ;;

     batch_create)
       echo "create from file $2"
       curl -X POST ${IRIS_URL}"/user/batch_create" ${COOKIE} -d "" -T $2 -v -i
       ;;

     delta2)
       curl -X POST "${IRIS_URL}/delta2/databox/"  -d "cursor="  ${COOKIE} -v -i
       ;;

     *)
       echo "unknown command..."
     ;;
esac
}

shift 1
process_cmd $@
