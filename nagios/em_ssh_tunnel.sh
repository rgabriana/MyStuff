#!/bin/bash -x

if [ -z "$1" ]; then
  echo "First Argument should be a valid id from the em_instance table"
  exit 1
fi

EMID=$1
RDB=emscloud
PSQL="/usr/bin/psql --username=DB1 --host=DB1 --dbname=${RDB} --no-align --quiet --tuples-only"
#SSHM="/usr/bin/ssh ops@cloudui.enlightedcloud.net"

SQL="SELECT count(*) from em_instance WHERE id=$EMID"
EXISTS=`$PSQL --command="${SQL}"`

if [ "$EXISTS" = 1 ]; then
  SQL="SELECT open_ssh_tunnel_to_cloud from em_instance WHERE id=$EMID"
  SSHSTATUS=`$PSQL --command="${SQL}"`
  if [ "$SSHSTATUS" = "t" ]; then
    NEWSTATUS="false"
  elif [ "$SSHSTATUS" = "f" ]; then
    NEWSTATUS="true"
  else
    echo "Could not determine ssh tunnel status of id: $EMID"
    exit 1
  fi
  SQL="UPDATE em_instance SET open_ssh_tunnel_to_cloud=${NEWSTATUS} WHERE id=${EMID}"
  $PSQL --command="${SQL}"
  SQL="SELECT count(*) from em_instance WHERE id=$EMID AND open_ssh_tunnel_to_cloud=${NEWSTATUS}"
  RESULT=`$PSQL --command="${SQL}"`
  if [ "$RESULT" = 1 ]; then
    echo "Updated EM id: $EMID open_ssh_tunnel_to_cloud to ${NEWSTATUS}"
  fi
else
  echo "Could not find EM with id: $EMID"
fi
