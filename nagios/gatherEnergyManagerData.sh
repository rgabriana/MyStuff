#!/bin/bash -x

#
# gatherEnergyManagerData.sh EM-<id>|<id>
#

if [[ $1 =~ ^EM ]]; then
  EMID=`echo $1 | sed s/EM-//`
elif [[ $1 =~ [0-9]+ ]]; then
  EMID=$1
else
  echo "Missing Argument (EnergyManager id)"
  exit 1
fi

SSHPORT=`cat /tmp/all_em.txt | grep ^${EMID} | awk -F '|' '{print $13}'`

if [ -z "$SSHPORT" ]; then
  echo "Could not find the ssh port"
  exit 1
fi

DATADIR="/etc/nagios3/EnergyManager.data/EM-${EMID}"
TMPDIR='/tmp/gatherEnergyManagerData'
SSHCONFIG=${TMPDIR}/ssh_config
SSH="/usr/bin/ssh -T -F ${SSHCONFIG}"

if [ ! -d "$DATADIR" ]; then
  mkdir -vp $DATADIR
fi
if [ ! -d "$TMPDIR" ]; then
  mkdir -vp $TMPDIR
fi

echo "ControlMaster auto" > ${SSHCONFIG}
echo "ControlPath ${TMPDIR}/%h_%p_%r" >> ${SSHCONFIG}
echo "ControlPersist 30" >> ${SSHCONFIG}
echo "Host *" >> ${SSHCONFIG}
echo " UserKnownHostsFile /dev/null" >> ${SSHCONFIG}
echo " StrictHostKeyChecking no" >> ${SSHCONFIG}
echo " Compression yes" >> ${SSHCONFIG}
echo " CompressionLevel 9" >> ${SSHCONFIG}
echo " GSSAPIAuthentication no" >> ${SSHCONFIG}
echo " AddressFamily inet" >> ${SSHCONFIG}
echo " ForwardAgent no" >> ${SSHCONFIG}
echo " ConnectTimeout 10" >> ${SSHCONFIG}
echo " BatchMode yes" >> ${SSHCONFIG}
echo " PasswordAuthentication no" >> ${SSHCONFIG}
echo " TCPKeepAlive yes" >> ${SSHCONFIG}
echo "Host master" >> ${SSHCONFIG}
echo " User ops" >> ${SSHCONFIG}
echo " IdentityFile ~/.ssh/id_dsa" >> ${SSHCONFIG}
echo " Hostname 192.168.0.15" >> ${SSHCONFIG}
echo "Host EM-*" >> ${SSHCONFIG}
echo " User enlighted" >> ${SSHCONFIG}
echo " IdentityFile ~/.ssh/identity" >> ${SSHCONFIG}
echo " ProxyCommand ${SSH} -q -W localhost:%p master" >> ${SSHCONFIG}
echo "Host EM-${EMID}" >> ${SSHCONFIG}
echo " Port ${SSHPORT}" >> ${SSHCONFIG}

COMMANDS[0]='date'
COMMANDS[1]='uptime'
COMMANDS[2]='cat /proc/cpuinfo'
COMMANDS[3]='df -h'
COMMANDS[4]='sudo du -h /var/lib/postgresql/' # get db size
COMMANDS[5]='vmstat'
COMMANDS[6]='sudo dmidecode'
COMMANDS[7]='ps aux'
COMMANDS[8]='sudo netstat -anp'
COMMANDS[9]='/sbin/ifconfig -a'
COMMANDS[10]='pstree'
COMMANDS[11]='dpkg -l'
COMMANDS[12]='lsusb'
COMMANDS[13]='free'
COMMANDS[14]='lspci'
COMMANDS[15]='last'
COMMANDS[16]='sudo lshw'
COMMANDS[17]='sudo biosdecode'
COMMANDS[18]='cat /proc/driver/nvram'
COMMANDS[19]='cat /etc/init/tunnel.conf'
COMMANDS[20]='cat /etc/bind/named.conf.options'

for (( i=0; i<${#COMMANDS[@]}; i++)); do
  if [ ! -s "${DATADIR}/${i}" ]; then
    ${SSH} EM-${EMID} "${COMMANDS[$i]}" > ${DATADIR}/${i}
  fi
done
