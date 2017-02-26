#!/bin/bash -x

if [ -n "$2" ]; then
  LOGLEVEL="$2"
else
  LOGLEVEL='INFO'
fi

echo "
Host EM-*
  User enlighted
  LogLevel $LOGLEVEL
  ProxyCommand /usr/bin/ssh -q -W localhost:%p master
"

cat $1 | while read LINE
do
  name=`echo $LINE | awk -F '|' '{print $1}'`
  port=`echo $LINE | awk -F '|' '{print $13}'`
  echo "Host EM-$name"
  echo "  Port $port"
done
