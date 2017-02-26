#!/bin/bash -x

for d in /etc/nagios3/EnergyManager.data/*; do

  test=`cat $d/10 | grep dhcpd`

  emid=`echo $d | sed -e s!/etc/nagios3/EnergyManager.data/!!`
  if [[ $test =~ dhcpd ]]; then
    echo "$emid found $test" > /dev/null
  else
    echo $emid
  fi

done
