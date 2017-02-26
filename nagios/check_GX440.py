#!/usr/bin/python

import paramiko
import time
import sys

#paramiko.common.logging.basicConfig(level=paramiko.common.DEBUG)
#print paramiko.__version__
em_ssh_port = int(sys.argv[1])

# connect to the master
masterClient = paramiko.SSHClient()
masterClient.set_missing_host_key_policy(paramiko.AutoAddPolicy())
masterClient.connect('192.168.0.15', username='ops', key_filename='/var/lib/nagios/.ssh/id_dsa')

# create a transport channel to the EM ssh port
masterTransport = masterClient.get_transport()
dest_addr = ('0.0.0.0', em_ssh_port)
local_addr = ('127.0.0.1', 2222)
emChannel = masterTransport.open_channel("direct-tcpip", dest_addr, local_addr)

# connect to the EM
emClient = paramiko.SSHClient()
emClient.set_missing_host_key_policy(paramiko.AutoAddPolicy())
emClient.connect('localhost', port=2222, username='enlighted', key_filename='/var/lib/nagios/.ssh/identity', sock=emChannel)

# create a transport channel to the SierraWireless LTE modem
modemTransport = emClient.get_transport()
dest_addr = ('192.168.13.31', 22)
local_addr = ('127.0.0.1', 22222)
modemChannel = modemTransport.open_channel("direct-tcpip", dest_addr, local_addr)

# connect to the modem
modemClient = paramiko.SSHClient()
modemClient.set_missing_host_key_policy(paramiko.AutoAddPolicy())
modemClient.connect('localhost', port=22222, username='user', password='12345', sock=modemChannel)

# invoke a shell
channel = modemClient.invoke_shell()
channel.setblocking(0)

output = ''
while(channel.recv_ready() is not True):
#  print 'Waiting for channel ready'
  time.sleep(0.5)

while(channel.recv_ready()):
#  print 'Waiting for OK prompt'
  buf=channel.recv(1)
  output += buf
  if (output[-4:] == "OK\r\n"):
#    print 'Got OK'
    break

channel.sendall('AT*GLOBALID?\nAT+CIMI?\nAT+ICCID?\nAT*NETOP?\nAT*NETSERV?\nAT*NETERR?\nAT*NETRSSI?\nAT*LTERSRQ?\nAT*LTERSRP?\nAT*CELLINFO?\nAT*CELLINFO2?\nAT*NETWDOG?\nAT*DATACURDAY?\nAT*DATAPREVDAY?\nAT*DATAPLANUNITS?\nAT*WANUPTIME?\nATI0?\nATI1?\nATI2?\nATNETIP?\nAT+HWTEMP?\nAT*NETCONNTYPE?\nAT*NETSERVICE_RAW?\nAT*DATACURDAY?\nAT*POWERIN?\nAT*SYSRESETS?')

loopCounter = 0
while(channel.exit_status_ready() is not True and channel.get_transport().is_active() is True and loopCounter < 60):
  time.sleep(0.1)
  loopCounter += 1
  while(channel.recv_ready()):
    buf=channel.recv(2048)
    output += buf

channel.close()
print output
