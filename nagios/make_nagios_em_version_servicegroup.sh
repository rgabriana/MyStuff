#!/bin/bash -x
##################################################
# Title: make_nagios_em_version_servicegroup.sh
# Usage: make_nagios_em_version_servicegroup.sh /tmp/all_em.txt
##################################################

ROOT_ID=0

if [ "$UID" -ne "$ROOT_ID" ]; then

  echo "You need root priveleges to run this program"
  exit 1

fi

set -e

OUTPUT=/etc/nagios3/conf.d/em-version.cfg

rm -vf $OUTPUT

# read the input file and create $OUTPUT1
cat $1 | while read LINE
do

  hostname=`echo $LINE | awk -F '|' '{print "EM-"$1}'`

  if [ -n "${group_members}" ]; then
    group_members=${group_members}','$hostname',version'
  else
    group_members=$hostname',version'
  fi
  echo "${group_members}" > /tmp/em_version

done

members=$(cat /tmp/em_version)
echo "define servicegroup{" >> $OUTPUT
echo "  servicegroup_name EM-version" >> $OUTPUT
echo "  members $members" >> $OUTPUT
echo "}" >> $OUTPUT

rm -vf /tmp/em_version
