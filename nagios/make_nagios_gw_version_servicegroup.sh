#!/bin/bash -x
##################################################
# Title: make_nagios_gw_version_servicegroup.sh
# Usage: make_nagios_gw_version_servicegroup.sh /home/ops/wip/4.1-GatewayHosts.csv
##################################################

ROOT_ID=0

if [ "$UID" -ne "$ROOT_ID" ]; then
  echo "You need root priveleges to run this program"
  exit 1
fi

set -e

OUTPUT=/etc/nagios3/conf.d/gw-version.cfg

rm -vf $OUTPUT

# read the input file and create $OUTPUT
cat $1 | while read LINE
do

  hostname=`echo $LINE | awk -F ';' '{print $1}'`

  if [ -n "${group_members}" ]; then
    group_members=${group_members}','$hostname',version'
  else
    group_members=$hostname',version'
  fi
  echo "${group_members}" > /tmp/gw_version

done

members=$(cat /tmp/gw_version)
echo "define servicegroup{" >> $OUTPUT
echo "  servicegroup_name GW-version" >> $OUTPUT
echo "  members $members" >> $OUTPUT
echo "}" >> $OUTPUT

rm -vf /tmp/gw_version
