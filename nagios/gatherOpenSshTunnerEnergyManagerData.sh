#!/bin/bash -x
##############################################
##############################################

IFS=$'\n'
for line in $(cat $1); do

  sshenable=`echo $line | awk -F '|' '{print $12}'`
  if [ "$sshenable" = "t" ]; then
    EMID=`echo $line | awk -F '|' '{print $1}'`
    (/bin/bash -x /etc/nagios3/bin/gatherEnergyManagerData.sh $EMID)
  fi

done
