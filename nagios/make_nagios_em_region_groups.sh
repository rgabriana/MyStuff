#!/bin/bash -x
########################################
# Title: make_nagios_em_region_groups.sh
# Usage: make_nagios_em_region_groups.sh /tmp.all_em.txt
########################################

ROOT_ID=0

if [ "$UID" -ne "$ROOT_ID" ]; then

  echo "You need root priveleges to run this program"
  exit 1

fi

set -e

OUTPUT=/etc/nagios3/conf.d/em-region.cfg

rm -vf $OUTPUT

ARRAY=()

# read the input file and create $OUTPUT
cat $1 | while read LINE
do

#  echo $LINE
  hostname=`echo $LINE | awk -F '|' '{print "EM-"$1}'`
  customer=`echo $LINE | awk -F '|' '{print $3}' | sed -e 's/ //g' | sed -e 's|&||g' | sed -e 's|(||g' | sed -e 's|)||g' | sed -e 's|\.||g' | sed -e 's|,||g' | sed -e 's|-|_|g'`
  region=`echo $LINE | awk -F '|' '{print $17}'`

  if [ -n "$region" ]; then
    group="${customer}__${region}"
    group_members="${group}_members"

    # array
#    ARRAY+=(${!group})

    if [ -n "${!group_members}" ]; then
#      echo "$group_members is NOT null"
      eval $group_members=${!group_members}','$hostname
#      echo "${!group_members}"
    else
#      echo "$group_members *IS* null"
      eval $group_members=$hostname
#      echo "${!group_members}"
    fi
    echo "${!group_members}" > /tmp/Region-${group_members}
  fi
#echo "${ARRAY[*]}"
done

cd /tmp
for f in Region-*_members; do
  group=`echo $f | sed -e s/_members$//g`
  members=$(cat /tmp/${f})
  echo "define hostgroup{" >> $OUTPUT
  echo "  hostgroup_name $group" >> $OUTPUT
  echo "  alias $group" >> $OUTPUT
  echo "  members $members" >> $OUTPUT
  echo "}" >> $OUTPUT
  rm -vf /tmp/${f}
done
cd -
