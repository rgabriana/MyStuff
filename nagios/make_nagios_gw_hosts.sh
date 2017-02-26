#!/bin/bash -x
#
# ./make_nagios_gw_hosts.sh /tmp/all_em.txt
#

ROOT_ID=0
if [ "$UID" -ne "$ROOT_ID" ]; then
  echo "You need root priveleges to run this program"
  exit 1
fi

TMPOUTPUT=/etc/nagios3/conf.d/em-gw-hosts.tmp
OUTPUT=/etc/nagios3/conf.d/em-gw-hosts.cfg
rm -vf $TMPOUTPUT
NCMD=/var/lib/nagios3/rw/nagios.cmd

HOURAGO=`/bin/date --date="1 hour ago" +%s`
DAYAGO=`/bin/date --date="1 day ago" +%s`
WEEKAGO=`/bin/date --date="1 week ago" +%s`
if perl -e 'exit ((localtime)[8])' ; then
  DST=28800
else
  DST=27360
fi

/bin/cp $1 ${1}.tmp

cat ${1}.tmp | while read LINE
do

  replicahost=`echo $LINE | awk -F '|' '{print $15}'`
  replicadb=`echo $LINE | awk -F '|' '{print $16}'`

  if [ "$replicahost" = "replica1.enlightedcloud.net" ]; then
    host=192.168.0.20
  elif [ "$replicahost" = "replica2.enlightedcloud.net" ]; then
    host=192.168.0.21
  elif [ "$replicahost" = "replica3.enlightedcloud.net" ]; then
    host=192.168.0.22
  elif [ "$replicahost" = "replica4.enlightedcloud.net" ]; then
    host=192.168.0.23
  elif [ "$replicahost" = "replica5.enlightedcloud.net" ]; then
    host=192.168.0.24
  elif [ "$replicahost" = "replica6.enlightedcloud.net" ]; then
    host=192.168.0.25
  elif [ "$replicahost" = "replica7.enlightedcloud.net" ]; then
    host=192.168.0.26
  elif [ "$replicahost" = "replica8.enlightedcloud.net" ]; then
    host=192.168.0.27
  elif [ "$replicahost" = "replica9.enlightedcloud.net" ]; then
    host=192.168.0.28
  elif [ "$replicahost" = "replica10.enlightedcloud.net" ]; then
    host=192.168.0.29
  elif [ "$replicahost" = "replica11.enlightedcloud.net" ]; then
    host=192.168.0.30
  elif [ "$replicahost" = "replica12.enlightedcloud.net" ]; then
    host=192.168.0.31
  elif [ "$replicahost" = "replica13.enlightedcloud.net" ]; then
    host=192.168.0.32
  fi

  EMID=`echo $replicadb | awk -F'_' '{print $NF}'`
  EM='EM-'$EMID

  PSQL="/usr/bin/psql --host=${host} --username=postgres --dbname=${replicadb} --no-align --quiet --tuples-only"
  SQL="SELECT id,snap_address,app1_version,last_connectivity_at,curr_no_pkts_from_nodes,boot_loader_version from gateway WHERE commissioned=true"
  RESULT=`${PSQL} --command="${SQL}"`

  OLDIFS=$IFS
  IFS=$'\n'

  for i in $RESULT
  do

    gateway_id=`echo $i | awk -F '|' '{print $1}'`
    IFS=$OLDIFS
    FixtureCount=`${PSQL} --command="SELECT count(id) FROM fixture WHERE state='COMMISSIONED' AND gateway_id='${gateway_id}'"`
#    FixtureCount1d=`${PSQL} --command="SELECT count(id) FROM fixture WHERE state='COMMISSIONED' AND gateway_id='${gateway_id}' AND last_connectivity_at < now() - interval '1 day'"`
    FixtureCount7d=`${PSQL} --command="SELECT count(id) FROM fixture WHERE state='COMMISSIONED' AND gateway_id='${gateway_id}' AND last_connectivity_at < now() - interval '7 day'"`
#    FixtureCount14d=`${PSQL} --command="SELECT count(id) FROM fixture WHERE state='COMMISSIONED' AND gateway_id='${gateway_id}' AND last_connectivity_at < now() - interval '14 day'"`
    FixtureCount30d=`${PSQL} --command="SELECT count(id) FROM fixture WHERE state='COMMISSIONED' AND gateway_id='${gateway_id}' AND last_connectivity_at < now() - interval '30 day'"`

    TMP=`echo "scale=2; ${FixtureCount30d}/${FixtureCount}" | bc`
    PERCENT=`echo "scale=0; ${TMP}*100/1" | bc`

    IFS=$'\n'
    last_connectivity_at=`echo $i | awk -F '|' '{print $4}'`
    curr_no_pkts_from_nodes=`echo $i | awk -F '|' '{print $5}'`
    TS1=`/bin/date --date="$last_connectivity_at" +%s`
    TS1=`expr $TS1 - $DST` # convert to PST
    S1='0' # 0=OK, 1=WARNING, 2=CRITICAL, 3=UNKNOWN
    H1='0' # 0=UP, 1=DOWN, 2=UNREACHABLE
    if [ $TS1 -lt $DAYAGO ]; then S1='1'; H1='2'; fi
    if [ $TS1 -lt $WEEKAGO ]; then S1='2'; H1='1'; fi

    gwMac=`echo $i | awk -F '|' '{print $2}' | sed -e s/://g`
    if [ -z "$gwMac" ]; then
      continue
    fi
    bootLoaderVersion=`echo $i | awk -F '|' '{print $6}'`
    bootLoader=`echo $i | awk -F '|' '{print $6}' | sed -e s/\\\.//g`
    versionBuild=`echo $i | awk -F '|' '{print $3}'`
    version=`echo $versionBuild | awk '{print $1}' | sed -e s/\\\.//g`
    if [ "$version" -lt "240" ]; then
      # needs additional upgrades
      version_state=3
    elif [ "$version" -lt "262" ]; then
      if [ "$bootLoader" -lt "25" ]; then
        version_state=1
      else
        version_state=2
      fi
    else
      version_state=0
    fi
    hostname=${EM}-GW-${gwMac}
    parent=$EM

    if [ "$curr_no_pkts_from_nodes" -eq "0" ]; then
      curr_no_pkts_from_nodes_state=2
      if [ "$H1" -eq "0" ]; then H1=2; fi
    else
      curr_no_pkts_from_nodes_state=0
    fi

    echo "define host{" >> $TMPOUTPUT
    echo "  use gw-host" >> $TMPOUTPUT
    echo "  host_name $hostname" >> $TMPOUTPUT
    echo "  parents $parent" >> $TMPOUTPUT
    echo "}" >> $TMPOUTPUT

    if [ "$PERCENT" -gt "5" ]; then
      fixtureCountStatus=1
    else
      fixtureCountStatus=0
    fi

    echo "[$TS1] PROCESS_HOST_CHECK_RESULT;$hostname;${H1}" >> $NCMD
    echo "[$TS1] PROCESS_SERVICE_CHECK_RESULT;$hostname;version;${version_state};$versionBuild (BL: $bootLoaderVersion)" >> $NCMD
    echo "[$TS1] PROCESS_SERVICE_CHECK_RESULT;$hostname;last_connectivity_at;${S1};$last_connectivity_at" >> $NCMD
    echo "[$TS1] PROCESS_SERVICE_CHECK_RESULT;$hostname;curr_no_pkts_from_nodes;${curr_no_pkts_from_nodes_state};$curr_no_pkts_from_nodes" >> $NCMD
    echo "[$TS1] PROCESS_SERVICE_CHECK_RESULT;$hostname;fixtures;${fixtureCountStatus};Total: $FixtureCount, 7d: $FixtureCount7d, 30d: $FixtureCount30d (${PERCENT}%)" >> $NCMD

  done
  IFS=$OLDIFS
done

/bin/cp -v $TMPOUTPUT $OUTPUT
/bin/rm -vf $TMPOUTPUT
/bin/rm -vf ${1}.tmp
