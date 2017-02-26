#!/bin/bash -x
##########################################
# Title: submit_passive_status.sh
# Usage: submit_passive_status.sh /tmp/all_em.txt
##########################################

ROOT_ID=0

if [ "$UID" -ne "$ROOT_ID" ]; then
  echo "You need root priveleges to run this program"
  exit 1
fi

### https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/3/en/passivechecks.html

HOURAGO=`/bin/date --date="1 hour ago" +%s`
DAYAGO=`/bin/date --date="1 day ago" +%s`
WEEKAGO=`/bin/date --date="1 week ago" +%s`
if perl -e 'exit ((localtime)[8])' ; then
  DST=28800
else
  DST=27360
fi

# read the input file and process
cat $1 | while read LINE
do
  customer=`echo $LINE | awk -F '|' '{print $3}'`

  last_connectivity_at=`echo $LINE | awk -F '|' '{print $5}'`
  TS1=`/bin/date --date="$last_connectivity_at" +%s`
  TS1=`expr $TS1 - $DST` # convert to PST

  hostname=`echo $LINE | awk -F '|' '{print "EM-"$1}'`
  last_successful_sync_time=`echo $LINE | awk -F '|' '{print $8}'`
  TS2=`/bin/date --date="$last_successful_sync_time" +%s`
  TS2=`expr $TS2 - $DST` # convert to PST

  os_version=`echo $LINE | awk -F '|' '{print $11}'`
  version=`echo $LINE | awk -F '|' '{print $14}'`
  ssh_tunnel_port=`echo $LINE | awk -F '|' '{print $13}'`
  replica=`echo $LINE | awk -F '|' '{print $15":"$16}'`
  pause_sync=`echo $LINE | awk -F '|' '{print $21}'`

  # checking last_connectivity_at
  S1='0'
  H1='0'
  if [ $TS1 -lt $HOURAGO ]; then S1='1'; H1='2'; fi
#  if [ $TS1 -gt $DAYAGO ] && [ $TS1 -gt $HOURAGO ]; then S1='1'; H1='2'; fi
  if [ $TS1 -lt $DAYAGO ]; then S1='2'; H1='1'; fi

  # checking last_successful_sync_time
  S2='0'
#  H2='0'
  if [ $TS2 -lt $HOURAGO ]; then S2='1'; H1='0'; fi
  if [ $TS2 -lt $DAYAGO ]; then S2='2'; H1='1'; fi

#  if [ "$customer" = 'AT&T-150' ]; then
    if [ $version = 3.5.2.7517 ]; then
      version_state='0'
    elif [ $version = 3.5.1.7413 ]; then
      version_state='0'
    else
      version_state='1'
    fi
#  fi

  pause_state='0'
  if [ "$pause_sync" = 't' ]; then
    pause_state='1'
  fi

  EMDATADIR='/etc/nagios3/EnergyManager.data'
  MANUFACTURER=`cat ${EMDATADIR}/${hostname}/6 | grep 'Manufacturer' | head -1 | awk '{print $2}'`
  MODEL=`cat ${EMDATADIR}/${hostname}/6 | grep 'Product Name' | head -1 | awk '{print $3}'`
  MODELVERSION=`cat ${EMDATADIR}/${hostname}/6 | grep 'Version' | head -2 | tail -1 | awk '{print $2}'`
  HWINFO="${MANUFACTURER} - ${MODEL} - ${MODELVERSION}"

### [<timestamp>] PROCESS_SERVICE_CHECK_RESULT;<host_name>;<svc_description>;<return_code>;<plugin_output>
### [<timestamp>] PROCESS_HOST_CHECK_RESULT;<host_name>;<host_status>;<plugin_output>
#OUTPUT=/tmp/submit_passive_status_test

  OUTPUT=/var/lib/nagios3/rw/nagios.cmd

  echo "[$TS1] PROCESS_HOST_CHECK_RESULT;$hostname;${H1};ssh_tunnel_port:${ssh_tunnel_port}, ${replica} | ${HWINFO}" >> $OUTPUT
  echo "[$TS1] PROCESS_SERVICE_CHECK_RESULT;$hostname;version;${version_state};$version" >> $OUTPUT
  echo "[$TS1] PROCESS_SERVICE_CHECK_RESULT;$hostname;last_connectivity_at;${S1};$last_connectivity_at" >> $OUTPUT
  echo "[$TS2] PROCESS_SERVICE_CHECK_RESULT;$hostname;last_successful_sync_time;${S2};$last_successful_sync_time" >> $OUTPUT
  echo "[$TS1] PROCESS_SERVICE_CHECK_RESULT;$hostname;pause_sync;${pause_state};$pause_sync" >> $OUTPUT

done
