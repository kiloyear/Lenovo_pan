TGZ=$1.tar.gz
BIN=$1.bin

if [ -f $TGZ ]; then
     echo "skip tar"
else
     tar zcvf $TGZ $1
fi

cp header.tmpl $BIN

declare -i LINE=$(wc -l $BIN |awk '{print $1}')
LINE=$LINE+1
sed -i "s/line_count=TO_BE_REPLACE/line_count=$LINE/" $BIN
sed -i "s/dragonball_tgz=TO_BE_REPLACE/dragonball_tgz=$TGZ/" $BIN

cat $TGZ >> $BIN
chmod a+x $BIN
