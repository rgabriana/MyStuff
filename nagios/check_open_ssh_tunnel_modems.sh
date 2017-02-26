#!/bin/bash -x
##############################################
# Title: check_open_ssh_tunnel_modems.sh
# Usage: /bin/bash check_open_ssh_tunnel_modems.sh /tmp/all_em.txt
##############################################

set +e

cat $1 | while read LINE
do

  hostname=`echo $LINE | awk -F '|' '{print "EM-"$1}'`
  customer=`echo $LINE | awk -F '|' '{print $3}'`
  sshenabled=`echo $LINE | awk -F '|' '{print $12}'`
  sshport=`echo $LINE | awk -F '|' '{print $13}'`
  random=`date +%s`

  if [ "$sshenabled" = "t" ] && [ "$customer" != "Indiana Govt Center-1250" ] && [ "$customer" != "GE-1000" ] && [ "$customer" != "Intuit-502" ] && [ "$customer" != "Uber-601" ]; then
# remove customer checks -paulp
# && [ "$customer" = "AT&T-150" ] || [ "$customer" = "HP-700" ] || [ "$customer" = "Linkedin-600" ] || [ "$customer" = "GAP-500" ] || [ "$customer" = "Mercy-1050" ] || [ "$customer" = "CSU Dominguez Hills-200" ] || [ "$customer" = "Procter and Gamble-650" ]; then

    echo "Checking $hostname ($customer)"
    file=/etc/nagios/airlink.data/${hostname}
#    file=~/airlink/${hostname}
#    newfile=~/airlink/${hostname}-${random}
    newfile=/etc/nagios/airlink.data/${hostname}-${random}

    # check if the file exists and get the size
    if [ -e "$file" ]; then
      size=$(wc -c <"$file")
      age=$(expr $(date +%s) - $(date +%s -r $file))
      Q=`grep ?$ $file|wc -l` #questions
      A=`grep 'OK\|ERROR' $file|wc -l` #answers
    else
      size=0
      age=0
    fi

    # check if file is zero size
    if [ "$size" = "0" ]; then
      echo "Getting $hostname Airlink details... (no previous data)"
      /usr/bin/python /etc/nagios/bin/check_GX440.py $sshport > $file
      /usr/bin/dos2unix -q $file $file #&> /dev/null

#      /bin/bash /etc/nagios3/bin/gatherEnergyManagerData.sh $hostname

    # check if the file is incomplete
    elif [ "$Q" != "$A" ]; then
      echo "Re-fetching $hostname Airlink details... (data is incomplete)"
      /usr/bin/python /etc/nagios/bin/check_GX440.py $sshport > $newfile
      /usr/bin/dos2unix -q $newfile $newfile #&> /dev/null

      # check if the file exists and get the size
      NewQ=`grep ?$ $newfile|wc -l` #questions
      NewA=`grep 'OK\|ERROR' $newfile|wc -l` #answers

      if [ "$NewQ" -gt "0" ] && [ "$NewQ" -eq "$NewA" ]; then
        mv -v $newfile $file
      else
        rm -vf $newfile
      fi

    # check the age of the file (greater than a day)
    elif [ "$age" -gt 86400 ]; then
      echo "Getting $hostname Airlink details... (data is stale - 1d)"
      /usr/bin/python /etc/nagios/bin/check_GX440.py $sshport > $newfile
      /usr/bin/dos2unix -q $newfile $newfile #&> /dev/null

#      /bin/bash /etc/nagios3/bin/gatherEnergyManagerData.sh $hostname

      # check if the file exists and get the size
      NewQ=`grep ?$ $newfile|wc -l` #questions
      NewA=`grep 'OK\|ERROR' $newfile|wc -l` #answers
      if [ "$NewQ" -gt "0" ] && [ "$NewQ" -eq "$NewA" ]; then
        mv -v $newfile $file
      else
        rm -vf $newfile
      fi
    fi

  fi

done
