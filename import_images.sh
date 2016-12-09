#!/bin/sh

vertag=$(cat /opt/dragonball/VERSION)

if [ -z $1 ]; then
     echo "no image path"
     exit 1
fi

img_path=$1
img_role=$2

if [ -z $img_role ]; then
     echo "load all images"
else
     echo "load $img_role"
     ball=${img_role}.ball
     img=`ls ${img_path}/$ball | grep tar 2>/dev/null`

     fullpath="${img_path}/$ball/$img"
     echo $fullpath

     docker load <$fullpath
     exit 0
fi

echo "Searching ball files in $img_path..."
#skip portal and registry...
Ball=`ls $img_path | grep ball | grep -v portal | grep -v registry`
echo $Ball
for ball in $Ball; do
     Img=`ls ${img_path}/${ball} | grep tar 2>/dev/null`
     if [ -z $Img ]; then
       continue;
     fi
     fullpath="${img_path}/${ball}/${Img}"
     echo "load $fullpath"
     docker load <$fullpath

     rolename=$(basename $ball .ball)
     app_ver=$(docker images | grep $rolename | awk '{print $1":"$2}')
     app_new=$(docker images | grep $rolename | awk '{print $1}'):$vertag
     docker tag $app_ver  $app_new

     echo "push $app_new"
     docker push $app_new
done
