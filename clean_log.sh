#!/bin/bash

#dup with tools/clean_log

declare -i max_size=524288000
function clean_file()
{
     logfile=$1
     declare -i filesize=$(wc -c $logfile |awk '{print $1}')

     if [ $filesize -gt $max_size ]; then
       tmpfile=/tmp/logfile.tmp

             tail -n 10000 $logfile > $tmpfile
       cat $tmpfile > $logfile
       /bin/rm -f $tmpfile
     fi
}

function clean_dir()
{
     dir="$1/"
     tmp=/tmp/"Log_$(date +%N).log"

     #delete files more that 30 days
     oldFiles=$(find $dir -type f -iname "*.log*"  -mmin +10080)
     for file in $oldFiles; do
       /bin/rm -f $file
     done

     oldFiles=$(find $dir -type f -iname "*error*"  -mmin +10080)
     for file in $oldFiles; do
       /bin/rm -f $file
     done

     largeFiles=$(find $dir -type f -iname "*.log*" -size +500M)
     for file in $largeFiles; do
       tail -n 10000 $file > $tmp
       cat $tmp > $file
     done

     largeFiles=$(find $dir -type f -iname "*error*" -size +500M)
     for file in $largeFiles; do
       tail -n 10000 $file > $tmp
       cat $tmp > $file
     done

     /bin/rm -f $tmp
}

dst=$1
if [ -d $dst ]; then
     clean_dir $dst
fi

if [ -f $dst ]; then
     clean_file $dst
fi
