#!/bin/bash -x
###################################
# Title: submit_airlink_status.sh
# usage: bash submit_airlink_status.sh /tmp/airlink_data
##################################

ROOT_ID=0

if [ "$UID" -ne "$ROOT_ID" ]; then
  echo "You need root priveleges to run this script"
  exit 1
fi

set -e

### https://assets.nagios.com/downloads/nagioscore/docs/nagioscore/3/en/passivechecks.html

DAYAGO=`/bin/date --date="1 day ago" +%s`
HOURAGO=`/bin/date --date="1 hour ago" +%s`

# read the input file and process

cat $1 | while read LINE
do

  em=`echo $LINE | awk -F '|' '{print $1}'`
  TS=$(date +%s -r /etc/nagios/airlink.data/$em)
  hostname=`echo $LINE | awk -F '|' '{print $2}'`
  hostname=$(echo -e "${hostname}" | tr -d '[[:space:]]')
  imsi=`echo $LINE | awk -F '|' '{print $3}'`
  sim=`echo $LINE | awk -F '|' '{print $4}'`
  netop=`echo $LINE | awk -F '|' '{print $5}'`
  netsrv=`echo $LINE | awk -F '|' '{print $6}'`
  neterr=`echo $LINE | awk -F '|' '{print $7}'`
  rssi=`echo $LINE | awk -F '|' '{print $8}'`
  rsrq=`echo $LINE | awk -F '|' '{print $9}'`
  rsrp=`echo $LINE | awk -F '|' '{print $10}'`
  nwdog=`echo $LINE | awk -F '|' '{print $13'}`

  netsrv_state='3'
  if [ "$netsrv" = 'LTE' ]; then
	netsrv_state='0'
  elif [ "$netsrv" = '3G' ];  then
	netsrv_state='1'
  elif [ "$netsrv" = 'UMTS' ]; then
	netsrv_state='1'
  fi

# for RSSI (Received Signal Strength Indicator)
#          > -70 dBm  == 0 (Excellent)
#  -70 dBm to -85 dBm == 0 (Good)
# -86 dBm to -100 dBm == 1 (Fair)
#          < -100 dBm == 2 (Poor)

  rssi_state='3'
  if [ "$netsrv" = 'LTE' ]; then
    if [ "$rssi" -ge -85 ]; then
      rssi_state='0'
    elif [ "$rssi" -le -86 ]; then
      rssi_state='1'
    elif [ "$rssi" -le -100 ]; then
      rssi_state='2'
    fi
  else
    if [ "$rssi" -ge -84 ]; then
      rssi_state='0'
    elif [ "$rssi" -le -85 ]; then
      rssi_state='1'
    elif [ "$rssi" -le -100 ]; then
      rssi_state='2'
    fi
  fi

# for RSRQ (Reference Signal Received Quality)
#        > -9 dB  == 0 (Excellent)
# -9 dB to -12 dB == 1 (Good)
#       < -13 dB  == 2 (Fair to Poor)

  rsrq_state='3'
  if [ "$netsrv" = "LTE" ]; then
    if [ "$rsrq" -ge -9 ]; then
        rsrq_state='0'
    elif [ "$rsrq" -ge -12 ]; then
        rsrq_state='1'
    elif [ "$rsrq" -le -13 ]; then
        rsrq_state='2'
    fi
  else
    rsrq="only applicable to LTE"
  fi

# for RSRP (Reference Signal Received Power)
#           > -90 dBm  == 0 (Excellent)
#  -90 dBm to -105 dBm == 0 (Good)
# -106 dBm to -120 dBm == 1 (Fair)
#           < -120 dBm == 2 (Poor)

  rsrp_state='3'
  if [ "$netsrv" = "LTE" ]; then
    if [ "$rsrp" -ge -105 ]; then
        rsrp_state='0'
    elif [ "$rsrp" -ge -119 ]; then
        rsrp_state='1'
    elif [ "$rsrp" -le -120 ]; then
        rsrp_state='2'
    fi
  else
    rsrp="only applicable to LTE"
  fi

#  for SINR (Signal Interference to Noise Ratio)
#	>= 6	 == 0 (Excellent)
#	1 to 5	 == 1 (Good)
#	< 0	 == 2 (Poor)

  sinr_state='3'
  if [ "$netsrv" = "LTE" ]; then
    sinr=`echo $LINE | awk -F '|' '{for (i=1;i<=NF;i++) {if ($i ~/LTESINR:|LTESNR:/) {print $i}}}'|awk -F ": " '{print $13}'|awk -F " " '{print $1}'`
    if [  ${sinr%.*} -ge 6 ]; then
      sinr_state='0'
    elif [ ${sinr%.*} -ge 1 ]; then
      sinr_state='1'
    elif [ ${sinr%.*} -le 0 ]; then
      sinr_state='2'
    fi
  else
    sinr="only applicable to LTE"
  fi

# for Network Error
# =0	== 0 (Excellent)
# !=0	== 2 (Poor)

  neterr_state='3'
  if [ "$neterr" -eq 0 ]; then
	neterr_state='0'
  else
	neterr_state='2'
  fi

# for Net Watchdog
# =120 == 0 (Excellent)
# !=120 ==2 (Poor)

  nwdog_state='3'
  if [ $nwdog -eq 120 ]; then
	nwdog_state='0'
  else
	nwdog_state='2'
  fi

### [<timestamp>] PROCESS_SERVICE_CHECK_RESULT;<host_name>;<svc_description>;<return_code>;<plugin_output>
### [<timestamp>] PROCESS_HOST_CHECK_RESULT;<host_name>;<host_status>;<plugin_output>
### Nagios Return codes: 0 == 'ok',1 == 'warning',2 == 'critical',3 == 'unknown'

#  OUTPUT=/tmp/testing
  OUTPUT=/var/lib/nagios3/rw/nagios.cmd

  hostname='SierraWireless-'${hostname}

#  echo "[$TS] PROCESS_HOST_CHECK_RESULT;$hostname;0;<A HREF=/cgi-bin/nagios3/extinfo.cgi?type=1&host=$em>$em</A>" >> $OUTPUT
  echo "[$TS] PROCESS_SERVICE_CHECK_RESULT;$hostname;SIM - ICCID;0;$sim" >> $OUTPUT
  echo "[$TS] PROCESS_SERVICE_CHECK_RESULT;$hostname;Subscriber Identity Module ID - IMSI;0;$imsi" >> $OUTPUT
  echo "[$TS] PROCESS_SERVICE_CHECK_RESULT;$hostname;Network Operator;0;$netop" >> $OUTPUT
  echo "[$TS] PROCESS_SERVICE_CHECK_RESULT;$hostname;Network Type;0;$netsrv" >> $OUTPUT
  echo "[$TS] PROCESS_SERVICE_CHECK_RESULT;$hostname;Network Service Type;${netsrv_state};$netsrv" >> $OUTPUT
  echo "[$TS] PROCESS_SERVICE_CHECK_RESULT;$hostname;Received Signal Strength Indicator - RSSI;${rssi_state};$rssi" >> $OUTPUT
  echo "[$TS] PROCESS_SERVICE_CHECK_RESULT;$hostname;Reference Signal Received Quality - RSRQ;${rsrq_state};$rsrq" >> $OUTPUT
  echo "[$TS] PROCESS_SERVICE_CHECK_RESULT;$hostname;Reference Signal Received Power - RSRP;${rsrp_state};$rsrp" >> $OUTPUT
  echo "[$TS] PROCESS_SERVICE_CHECK_RESULT;$hostname;Signal to Interference plus Noise Ratio - SINR;${sinr_state};$sinr" >> $OUTPUT
  echo "[$TS] PROCESS_SERVICE_CHECK_RESULT;$hostname;Network Error Rate;${neterr_state};$neterr" >> $OUTPUT
  echo "[$TS] PROCESS_SERVICE_CHECK_RESULT;$hostname;Network WatchDog Timer;${nwdog_state};$nwdog" >> $OUTPUT

  # Session Info
  ### this is a hack for a SIM that is not part of our JasperWireless Service
  if   [ "$sim" = "89014103278002875972" ]; then
    session='Wed Dec 31 16:00:00 1969 - UNKNOWN (not in JasperWireless)'
  elif [ "$sim" = "2" ]; then
    session='Wed Dec 31 16:00:00 1969'
  else
    echo "Checking session for $sim"
    session=`/usr/bin/perl /etc/nagios/bin/check_jasperwireless_session $sim`
  fi

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
  NOW=$(date +%s)
  echo "[$NOW] PROCESS_SERVICE_CHECK_RESULT;$hostname;Session Information;$status;$session" >> $OUTPUT

  # change this to a host status
  if [ "$status" != "0" ]; then
    if [ "$status" != "1" ]; then
      status="1"
    else
      status="0"
    fi
  fi
  echo "[$TS] PROCESS_HOST_CHECK_RESULT;$hostname;${status};<A HREF=/cgi-bin/nagios3/extinfo.cgi?type=1&host=$em>$em</A>" >> $OUTPUT

  if [ "$TS" -gt "$HOURAGO" ]; then
    if [[ $session =~ "Wed Dec 31 16:00:00 1969" ]]; then
      echo "Skipping $sim"
    else
      # set DeviceId
      echo "$sim -> $em"
      `/usr/bin/perl /etc/nagios/bin/set_jasperwireless_deviceId $sim $em`

      # set Customer (must already exist!)
      EMID=`echo $em | sed -e s/^EM-//`
      EMINFO=`cat /tmp/all_em.txt | grep ^${EMID}\|`
      customer=`echo $EMINFO | awk -F \| '{print $3}' | awk -F - '{print $1}' | sed -e s/\&// | sed -e s/\.//g | sed -e s/\,//g`
      echo "$sim -> $customer"
      `/usr/bin/perl /etc/nagios/bin/set_jasperwireless_customer $sim "$customer"`
    fi
  else
    echo "No need to set Jasper Portal for $sim (no new data)"
  fi

done

# SASSI
#/bin/bash +x /etc/nagios/bin/sassi.sh
