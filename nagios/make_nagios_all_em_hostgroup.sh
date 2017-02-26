#!/bin/bash -x
##########################################
# Title: make_nagios_all_em_hostgroup.sh
# Usage: make_nagios_all_em_hostgroup.sh
##########################################

ROOT_ID=0

if [ "$UID" -ne "$ROOT_ID" ]; then

  echo "You need root priveleges to run this program"
  exit 1

fi

GROUP=/tmp/all-em-hostgroupgroup-${RANDOM}

OUTPUT=/etc/nagios3/conf.d/all-em.cfg

rm -vf $OUTPUT

# read the input file and create entries
cat /tmp/all_em.txt | while read LINE
do

  hostname=`echo $LINE | awk -F '|' '{print "EM-"$1}'`

  if [ -z "$group_members" ]; then
    group_members=$hostname;
  else
    group_members=$group_members','$hostname
  fi

  # save these to the FS
  echo $group_members > $GROUP

done

# reading from the FS
group_members=$(cat $GROUP)

echo "define hostgroup{" >> $OUTPUT
echo "  hostgroup_name ALL-EMs" >> $OUTPUT
echo "  alias All EnergyManagers" >> $OUTPUT
echo "  members $group_members" >> $OUTPUT
echo "}" >> $OUTPUT

rm -f $GROUP
