#!/bin/bash -x
##################################################
# Title: make_nagios_all_fixture_servicegroup.sh
# Usage: make_nagios_all_fixture_servicegroup.sh /tmp/all_em.txt
##################################################

ROOT_ID=0

if [ "$UID" -ne "$ROOT_ID" ]; then

  echo "You need root priveleges to run this program"
  exit 1

fi

set -e

OUTPUT1=/etc/nagios3/conf.d/em-fixture-servicegroup.cfg
OUTPUT2=/etc/nagios3/conf.d/em-att-fixture-servicegroup.cfg

rm -vf $OUTPUT1
rm -vf $OUTPUT2

# read the input file and create $OUTPUT1
cat $1 | while read LINE
do

  hostname=`echo $LINE | awk -F '|' '{print "EM-"$1}'`
  customer=`echo $LINE | awk -F '|' '{print $3}'`

    if [ "$customer" = "AT&T-150" ]; then
      if [ -n "${att_group_members}" ]; then
        att_group_members=${att_group_members}','$hostname',sensors with no data for over 30d'
      else
        att_group_members=$hostname',sensors with no data for over 30d'
      fi
    else
      if [ -n "${group_members}" ]; then
        group_members=${group_members}','$hostname',sensors with no data for over 30d'
      else
        group_members=$hostname',sensors with no data for over 30d'
      fi
    fi
    echo "${att_group_members}" > /tmp/att-fixture-servicegroup
    echo "${group_members}" > /tmp/fixture-servicegroup

done

members=$(cat /tmp/fixture-servicegroup)
echo "define servicegroup{" >> $OUTPUT1
echo "  servicegroup_name sensors_30d" >> $OUTPUT1
echo "  members $members" >> $OUTPUT1
echo "}" >> $OUTPUT1

members=$(cat /tmp/att-fixture-servicegroup)
echo "define servicegroup{" >> $OUTPUT2
echo "  servicegroup_name att-sensors_30d" >> $OUTPUT2
echo "  members $members" >> $OUTPUT2
echo "}" >> $OUTPUT2

rm -vf /tmp/att-fixture-servicegroup
rm -vf /tmp/fixture-servicegroup
