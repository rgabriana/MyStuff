#!/bin/bash -x
##################################################
# Title: make_nagios_all_gw_servicegroup.sh
# Usage: make_nagios_all_gw_servicegroup.sh /tmp/all_em.txt
##################################################

ROOT_ID=0

if [ "$UID" -ne "$ROOT_ID" ]; then

  echo "You need root priveleges to run this program"
  exit 1

fi

set -e

OUTPUT1=/etc/nagios3/conf.d/em-gw-servicegroup.cfg
OUTPUT2=/etc/nagios3/conf.d/em-att-gw-servicegroup.cfg

rm -vf $OUTPUT1
rm -vf $OUTPUT2

# read the input file and create $OUTPUT1
cat $1 | while read LINE
do

  hostname=`echo $LINE | awk -F '|' '{print "EM-"$1}'`
  customer=`echo $LINE | awk -F '|' '{print $3}'`

    if [ "$customer" = "AT&T-150" ]; then
      if [ -n "${att_group_members}" ]; then
        att_group_members=${att_group_members}','$hostname',gateways not seen in over 1d'
      else
        att_group_members=$hostname',gateways not seen in over 1d'
      fi
    else 
      if [ -n "${group_members}" ]; then
        group_members=${group_members}','$hostname',gateways not seen in over 1d'
      else
        group_members=$hostname',gateways not seen in over 1d'
      fi
    fi
    echo "${att_group_members}" > /tmp/att-gw-servicegroup
    echo "${group_members}" > /tmp/gw-servicegroup

done

members=$(cat /tmp/gw-servicegroup)
echo "define servicegroup{" >> $OUTPUT1
echo "  servicegroup_name gateways" >> $OUTPUT1
echo "  members $members" >> $OUTPUT1
echo "}" >> $OUTPUT1

members=$(cat /tmp/att-gw-servicegroup)
echo "define servicegroup{" >> $OUTPUT2
echo "  servicegroup_name att-gateways" >> $OUTPUT2
echo "  members $members" >> $OUTPUT2
echo "}" >> $OUTPUT2



members=$(cat /tmp/gw-servicegroup | sed -e 's/gateways not seen in over 1d/browsable_link/g')
echo "define servicegroup{" >> $OUTPUT1
echo "  servicegroup_name browsable_link" >> $OUTPUT1
echo "  members $members" >> $OUTPUT1
echo "}" >> $OUTPUT1
members=$(cat /tmp/att-gw-servicegroup | sed -e 's/gateways not seen in over 1d/browsable_link/g')
echo "define servicegroup{" >> $OUTPUT2
echo "  servicegroup_name att-browsable_link" >> $OUTPUT2
echo "  members $members" >> $OUTPUT2
echo "}" >> $OUTPUT2



#members=$(cat /tmp/gw-servicegroup | sed -e 's/gateways not seen in over 1d/cloud_config upgradeStatus/g')
#echo "define servicegroup{" >> $OUTPUT1
#echo "  servicegroup_name cloud_config-upgradeStatus" >> $OUTPUT1
#echo "  members $members" >> $OUTPUT1
#echo "}" >> $OUTPUT1
#members=$(cat /tmp/att-gw-servicegroup | sed -e 's/gateways not seen in over 1d/cloud_config upgradeStatus/g')
#echo "define servicegroup{" >> $OUTPUT2
#echo "  servicegroup_name att-cloud_config-upgradeStatus" >> $OUTPUT2
#echo "  members $members" >> $OUTPUT2
#echo "}" >> $OUTPUT2



rm -vf /tmp/att-gw-servicegroup
rm -vf /tmp/gw-servicegroup
