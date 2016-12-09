#!/bin/bash

OF_LIMIT=65535
OF_LIMIT_MIN=30000
OF_PROFILE_PATH=/etc/profile.d/open_file_limit.sh
OF_PAM_LIMIT_PATH=/etc/security/limits.d/open_file_limit.conf

set_open_file()
{
    ulimit -n $OF_LIMIT
    echo "ulimit -n $OF_LIMIT"  > $OF_PROFILE_PATH
    echo "*          soft    nofile     $OF_LIMIT"  > $OF_PAM_LIMIT_PATH
    echo "*          hard    nofile     $OF_LIMIT"  >> $OF_PAM_LIMIT_PATH
}



check_open_file()
{
    OF_LIMIT_NOW=$(ulimit -n)
    if [[ $OF_LIMIT_NOW < $OF_LIMIT_MIN ]]
    then
        echo "ulimit open file is: $OF_LIMIT_NOW"
        while true;
        do
            echo "we will set open file limit to $OF_LIMIT"
            echo -n "confirm(need reboot system manually)? [yes/no]:"
            read input
            if [ "$input" = "yes" ]; then
                set_open_file
                break
            fi  
            if [ "$input" = "no" ]; then
                echo "we will do nothing, you need config manually."
                break
            fi
        done
    fi
}


check_open_file
