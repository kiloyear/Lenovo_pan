#!/bin/bash

SQLCMD="mysql -uroot -plenovolabs iris_v40 -e "

$SQLCMD "delete from iris_name_entry where path<>'/'"
$SQLCMD "truncate iris_journal_entry"
$SQLCMD "truncate iris_version_entry;"
$SQLCMD "truncate iris_file_info;"
$SQLCMD "truncate iris_file_region_reference;"
$SQLCMD "truncate iris_extra_metadata;"

$SQLCMD "update iris_user set used=0;"
$SQLCMD "update iris_account_quota set space_used = 0;"
$SQLCMD "update iris_team set used=0;"
$SQLCMD "update iris_config set index_cursor=0"

#$SQLCMD "truncate iris_delivery;"
#$SQLCMD "truncate iris_user where id>1;"
#$SQLCMD "truncate iris_account_user where uid>1;"
#$SQLCMD "truncate iris_namespace where uid>1;"
#$SQLCMD "truncate iris_team;"
#$SQLCMD "truncate iris_team_user;"
#$SQLCMD "truncate iris_binding;"

#gamma
mysql -uroot -plenovolabs gamma -e "truncate gamma_object"
