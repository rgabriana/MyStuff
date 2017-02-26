#!/bin/bash -x

HOURNOW=`/bin/date +%k | sed -e 's/ //'`
HOURPRE=`/bin/date --date="1 hour ago" +%k | sed -e 's/ //'`

# read the input file
cat /tmp/all_em.txt | while read L
do
  EMID=`echo $L | awk -F '|' '{print $1}'`
  SSHT=`echo $L | awk -F '|' '{print $12}'`
  let "M = $EMID % 24"
  FORCEDOPEN=`cat /etc/nagios/open_ssh_tunnels.txt | grep ^EM-${EMID} | wc -l`
  if [ "$FORCEDOPEN" = "1" ]; then
    if [ "$SSHT" = "f" ]; then
      echo "Flipping open (EM-${EMID}) from whitelist"
      var=$(/bin/bash +x /etc/nagios/bin/em_ssh_tunnel.sh "$EMID" < /dev/null)
    fi
  elif [ "$M" = "$HOURNOW" ] && [ "$SSHT" = "f" ]; then
    echo "Flipping open current hour ${M}:00 - (EM-${EMID})"
    var=$(/bin/bash +x /etc/nagios/bin/em_ssh_tunnel.sh "$EMID" < /dev/null)
    echo $var
  elif  [ "$M" = "$HOURPRE" ] && [ "$SSHT" = "t" ]; then
    echo "Flipping closed previous hour ${M}:00 - (EM-${EMID})"
    var=$(/bin/bash +x /etc/nagios/bin/em_ssh_tunnel.sh "$EMID" < /dev/null)
    echo $var
  else
    echo "Skipping EM-${EMID}, will flip at ${M}:00"
  fi
done

