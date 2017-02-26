#!/bin/bash -x
##########################################
# Title: make_nagios_gx440.sh
# usage: make_nagios_gx440.sh /tmp/airlink_data
#########################################

ROOT_ID=0

if [ "$UID" -ne "$ROOT_ID" ]; then

  echo "You need root priveleges to run this program"
  exit 1

fi

set -e

sierrawirelesshosts=/etc/nagios/conf.d/sierrawireless-hosts.cfg
members_file=$(mktemp)
servicegroup_file=$(mktemp)

#lets clean up the old files
rm -vf $sierrawirelesshosts

#Begin reading the input file
cat $1|while read input
do
  em=`echo $input| awk -F "|" '{print $1}'`
  gid=`echo $input| awk -F "|" '{print $2}'`
  gid='SierraWireless-'${gid}

  ### !!! total hack to remove Franklin's modem !!! ###
  if [ "$gid" == "SierraWireless-A144550567001009" ]; then
    continue
  elif [ "$gid" == "SierraWireless-LA54750455001003" ]; then
    continue
  fi

  #First lets create a list of host for the the hostgroup
  echo "#4G_Host $em" >> $sierrawirelesshosts
  echo "define host{" >> $sierrawirelesshosts
  echo "  use sierrawireless-host" >> $sierrawirelesshosts
  echo "  host_name $gid" >> $sierrawirelesshosts
  echo "}" >> $sierrawirelesshosts

  if [ -z "$groupmembers" ]; then
    groupmembers=$gid
    servicegroup=$gid',Signal to Interference plus Noise Ratio - SINR'
  else
    groupmembers=$groupmembers','$gid
    servicegroup=$servicegroup','$gid',Signal to Interference plus Noise Ratio - SINR'
  fi
  echo $groupmembers > $members_file
  echo $servicegroup > $servicegroup_file
done

members=$(cat $members_file)
echo "#4G_Group" >> $sierrawirelesshosts
echo "define hostgroup{" >> $sierrawirelesshosts
echo "  hostgroup_name SierraWireless" >> $sierrawirelesshosts
echo "  members $members" >> $sierrawirelesshosts
echo "}" >> $sierrawirelesshosts

members=$(cat $servicegroup_file)
echo "define servicegroup{" >> $sierrawirelesshosts
echo "  servicegroup_name WAN_SINR" >> $sierrawirelesshosts
echo "  members $members" >> $sierrawirelesshosts
echo "}" >> $sierrawirelesshosts
members=`echo $members | sed -e 's/Signal to Interference plus Noise Ratio - SINR/Session Information/g'`
echo "define servicegroup{" >> $sierrawirelesshosts
echo "  servicegroup_name WAN_Session_Info" >> $sierrawirelesshosts
echo "  members $members" >> $sierrawirelesshosts
echo "}" >> $sierrawirelesshosts

rm -vf $members_file $servicegroup_file
