#!/bin/bash
##################################################
# Title: patchdist.sh
# Usage: bash patchdist.sh /tmp/all_em.txt
# Version: 1.0 
# Date: 4/19/2016
##################################################

if [ -z "$1" ]; then

  echo "please provide a list of EMs to distribute pateches to"
  exit

elif [ ! -f "$1" ]; then

  echo "Cannot find EM list please provide file location of EM list"
  exit

elif [ ! -s "$1" ]; then

  echo "file is empty, please provide a valid EM list"
  exit

fi

# create a new list of EMs for ssh
echo "ControlMaster auto" > ~/.ssh/config
echo "ControlPath ~/.ssh/%h_%p_%r" >> ~/.ssh/config
echo "ControlPersist 30" >> ~/.ssh/config
echo "" >> ~/.ssh/config
echo "Host *" >> ~/.ssh/config
echo "  ConnectTimeout 10" >> ~/.ssh/config
echo "  IdentityFile ~/.ssh/identity" >> ~/.ssh/config
echo "  PreferredAuthentications publickey" >> ~/.ssh/config
echo "  StrictHostKeyChecking no" >> ~/.ssh/config
echo "" >> ~/.ssh/config
echo "Host master" >> ~/.ssh/config
echo "  User ops" >> ~/.ssh/config
echo "  IdentityFile ~/.ssh/id_dsa" >> ~/.ssh/config
echo "Hostname cloudui.enlightedcloud.net" >> ~/.ssh/config
echo "" >> ~/.ssh/config
~/bin/make_em_ssh_config.sh $1 >> ~/.ssh/config


cat $1 | while read input

do

patch=/etc/nagios/em_data/patch
target=/home/enlighted/
em_id=`echo $input | awk -F "|" '{print "EM-"$1}'`
ssht=`echo $input | awk -F "|" '{print $12}'`

if [ "$ssht" != "f" ]; then  #Check if the ssh tunnel is open

  echo "Tunnel is open for $em_id"

  rsync -vcrzP -e /usr/bin/ssh $patch $em_id:$target
  
    if [ "$?" = "0" ]; then 
    echo "`date`: patch transfer complete for $em_id"  
    fi 

else

  echo "`date`: Tunnel not open for $em_id"

fi

done

exit 0
