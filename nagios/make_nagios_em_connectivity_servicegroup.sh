#!/bin/bash -x
##################################################
# Title: make_nagios_em_connectivity_servicegroup.sh
# Usage: make_nagios_em_connectivity_servicegroup.sh /tmp/all_em.txt
##################################################

ROOT_ID=0

if [ "$UID" -ne "$ROOT_ID" ]; then

  echo "You need root priveleges to run this program"
  exit 1

fi

set -e

OUTPUT1=/etc/nagios3/conf.d/em-connectivity.cfg
OUTPUT2=/etc/nagios3/conf.d/em-att-connectivity.cfg

rm -vf $OUTPUT1
rm -vf $OUTPUT2

# read the input file and create $OUTPUT1
cat $1 | while read LINE
do

  hostname=`echo $LINE | awk -F '|' '{print "EM-"$1}'`
  customer=`echo $LINE | awk -F '|' '{print $3}'`

    if [ "$customer" = "AT&T-150" ]; then
      if [ -n "${att_group_members}" ]; then
        att_group_members=${att_group_members}','$hostname',last_connectivity_at,'$hostname',last_successful_sync_time'
      else
        att_group_members=$hostname',last_connectivity_at,'$hostname',last_successful_sync_time'
      fi
    else 
      if [ -n "${group_members}" ]; then
        group_members=${group_members}','$hostname',last_connectivity_at,'$hostname',last_successful_sync_time'
      else
        group_members=$hostname',last_connectivity_at,'$hostname',last_successful_sync_time'
      fi
    fi
    echo "${att_group_members}" > /tmp/att-connectivity
    echo "${group_members}" > /tmp/connectivity

done

members=$(cat /tmp/connectivity)
echo "define servicegroup{" >> $OUTPUT1
echo "  servicegroup_name connectivity" >> $OUTPUT1
echo "  members $members" >> $OUTPUT1
echo "}" >> $OUTPUT1

members=$(cat /tmp/att-connectivity)
echo "define servicegroup{" >> $OUTPUT2
echo "  servicegroup_name att-connectivity" >> $OUTPUT2
echo "  members $members" >> $OUTPUT2
echo "}" >> $OUTPUT2

rm -vf /tmp/att-connectivity /tmp/connectivity
