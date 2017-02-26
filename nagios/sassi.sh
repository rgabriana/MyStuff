#!/bin/bash -x

ROOT_ID=0

if [ "$UID" -ne "$ROOT_ID" ]; then

  echo "You need root priveleges to run this script"
  exit 1

fi

set -e

# SASSI - ask Q
SASSI='/etc/nagios3/sassi.txt'
TS=$(date +%s)
OUTPUT=/var/lib/nagios3/rw/nagios.cmd
if [ -e $SASSI ]; then
  cat $SASSI | while read LINE
  do
    host=`echo $LINE | awk -F ',' '{print $1}'`
    sim=`echo $LINE | awk -F ',' '{print $2}'`

    # Session Info
    session=`/usr/bin/perl /etc/nagios/bin/check_jasperwireless_session $sim`
    if [[ $session =~ "Wed Dec 31 16:00:00 1969" ]]; then
      status="3"
    elif [[ $session =~ m$ ]]; then
      status="2"
    elif [[ $session =~ h$ ]]; then
      status="1"
    else
      status="0"
    fi
    echo "$sim -> Got session from API ($session)"
    echo "[$TS] PROCESS_SERVICE_CHECK_RESULT;$host;Session Information;$status;$session" >> $OUTPUT
  done
fi
