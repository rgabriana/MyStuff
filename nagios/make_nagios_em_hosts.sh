#!/bin/bash -x
########################################
# Title: make_nagios_em_hosts.sh
# usage: make_nagios_em_hosts.sh /tmp/all_em.txt
########################################

ROOT_ID=0

if [ "$UID" -ne "$ROOT_ID" ]; then

  echo "You need root priveleges to run this program"
  exit 1

fi

LASTGROUPSITE=/tmp/lastgroupsite-${RANDOM}
LASTGROUPCUSTOMER=/tmp/lastgroupcustomer-${RANDOM}
GROUPMEMBERSSITE=/tmp/groupmemberssite-${RANDOM}
GROUPMEMBERSCUSTOMER=/tmp/groupmemberscustomer-${RANDOM}
SSHHOSTS=/tmp/sshhosts-${RANDOM}

OUTPUT=/etc/nagios3/conf.d/em.cfg
SSHSERVICE=/etc/nagios3/conf.d/em-ssh.cfg
FIXTURESERVICE=/etc/nagios3/conf.d/em-fixture.cfg
GATEWAYSERVICE=/etc/nagios3/conf.d/em-gateway.cfg
GWHostFile=/etc/nagios3/conf.d/em-gw-hosts.cfg

rm -vf $OUTPUT
rm -vf $SSHSERVICE
rm -vf $FIXTURESERVICE
rm -vf $GATEWAYSERVICE

# read the input file and create entries
cat $1 | while read LINE
do

  hostname=`echo $LINE | awk -F '|' '{print "EM-"$1}'`
  site=`echo $LINE | awk -F '|' '{print $2}'`
  customer=`echo $LINE | awk -F '|' '{print $3}'`
  alias=`echo $LINE | awk -F '|' '{print $3" : "$4}'`
  sshenabled=`echo $LINE | awk -F '|' '{print $12}'`
  sshport=`echo $LINE | awk -F '|' '{print $13}'`
  replicahost=`echo $LINE | awk -F '|' '{print $15}'`
  replicadb=`echo $LINE | awk -F '|' '{print $16}'`

  if [ "$last_site" != "$site" ] && [ -n "$last_site" ]; then
    site_hostgroup_name=`echo $last_site | sed -e 's/ //g' | sed -e 's|&||g' | sed -e 's|(||g' | sed -e 's|)||g' | sed -e 's|\.||g' | sed -e 's|,||g'`
    customer_hostgroup_name=`echo $last_customer | sed -e 's/ //g' | sed -e 's|&||g' | sed -e 's|(||g' | sed -e 's|)||g' | sed -e 's|\.||g' | sed -e 's|,||g'`
    site_hostgroup_name='Site-'$customer_hostgroup_name'-'$site_hostgroup_name
    echo "# SITE hostgroup" >> $OUTPUT
    echo "define hostgroup{" >> $OUTPUT
    echo "  hostgroup_name $site_hostgroup_name" >> $OUTPUT
    echo "  alias $last_site" >> $OUTPUT
    echo "  members $site_group_members" >> $OUTPUT
    echo "}" >> $OUTPUT
    if [ -z "$site" ]; then
      site_group_members=""
    else
       if [ $(grep -c -i "${hostname}-GW-" ${GWHostFile}) -eq 0 ]; then  #If no gateways defined, then just omit the GW wildcard.
          site_group_members=$hostname
       else
          site_group_members=$hostname','${hostname}'-GW-.*'
       fi
    fi
  else
    # $site is zero length
    if [ -z "$site" ]; then
      site_group_members=""
    # $site_group_members is zero length
    elif [ -z "$site_group_members" ]; then
       if [ $(grep -c -i "${hostname}-GW-" ${GWHostFile}) -eq 0 ]; then  #If no gateways defined, then just omit the GW wildcard.
          site_group_members=$hostname
       else
      site_group_members=$hostname','${hostname}'-GW-.*'
       fi
    else
       if [ $(grep -c -i "${hostname}-GW-" ${GWHostFile}) -eq 0 ]; then  #If no gateways defined, then just omit the GW wildcard.
          site_group_members=$site_group_members','$hostname
       else
      site_group_members=$site_group_members','$hostname','${hostname}'-GW-.*'
       fi
    fi
  fi

  if [ "$last_customer" != "$customer" ] && [ -n "$last_customer" ]; then
    customer_hostgroup_name=`echo $last_customer | sed -e 's/ //g' | sed -e 's|&||g' | sed -e 's|(||g' | sed -e 's|)||g' | sed -e 's|\.||g' | sed -e 's|,||g'`
    customer_hostgroup_name='Customer-'$customer_hostgroup_name
    echo "# CUSTOMER hostgroup" >> $OUTPUT
    echo "define hostgroup{" >> $OUTPUT
    echo "  hostgroup_name $customer_hostgroup_name" >> $OUTPUT
    echo "  alias $last_customer" >> $OUTPUT
    echo "  members $customer_group_members" >> $OUTPUT
    echo "}" >> $OUTPUT
    customer_group_members=$hostname
  else
    if [ -z "$customer_group_members" ]; then
      customer_group_members=$hostname
    else
      customer_group_members=$customer_group_members','$hostname
    fi
  fi

  parents=`cat /tmp/airlink_data | grep $hostname\| | awk -F "|" '{print $2}' | uniq`
  parents=$(echo -e "${parents}" | tr -d '[[:space:]]')

  echo "define host{" >> $OUTPUT
  echo "  use em-host" >> $OUTPUT
  echo "  host_name $hostname" >> $OUTPUT
  echo "  alias $alias" >> $OUTPUT
#  echo "  display_name $displayname" >> $OUTPUT
  if [ -n "$parents" ]; then
    parents='SierraWireless-'${parents}
    #### !!!! total hack !!!! ####
    if [ "$parents" == "SierraWireless-A144550567001009" ]; then
      echo "  parents Franklin"
    elif [ "$parents" == "SierraWireless-LA54750455001003" ]; then
      echo "  parents Franklin"
    else
      echo "  parents $parents" >> $OUTPUT
    fi
  fi
  echo "}" >> $OUTPUT

  last_site=$site
  last_customer=$customer

  # for hosts with ssh tunnel enabled
  if [ "$sshenabled" = "t" ]; then

    # the ssh service
    echo "define service{" >> $SSHSERVICE
    echo "  use em-service-ssh" >> $SSHSERVICE
    echo "  host_name $hostname" >> $SSHSERVICE
    echo "  service_description ssh_tunnel_port" >> $SSHSERVICE
    echo "  check_command check_ssh_tunnel_port!$sshport" >> $SSHSERVICE
#    echo "  register 0" >> $SSHSERVICE
    echo "}" >> $SSHSERVICE

    # the ssh service
    echo "define service{" >> $SSHSERVICE
    echo "  use em-service-ssh" >> $SSHSERVICE
    echo "  host_name $hostname" >> $SSHSERVICE
    echo "  service_description 4G" >> $SSHSERVICE
    echo "  check_command check_4G!$sshport" >> $SSHSERVICE
    echo "  register 0" >> $SSHSERVICE
    echo "}" >> $SSHSERVICE

    if [ "$sshhosts" != "" ]; then
      sshhosts=$sshhosts','$hostname',ssh_tunnel_port'
    else
      sshhosts=$hostname',ssh_tunnel_port'
    fi
  fi

  # for fixture count
  echo "define service{" >> $FIXTURESERVICE
  echo "  use em-service-fixture" >> $FIXTURESERVICE
  echo "  host_name $hostname" >> $FIXTURESERVICE
  echo "  service_description sensors with no data for 7d" >> $FIXTURESERVICE
  echo "  check_command check_em_fixture_7d_failures!$replicahost!$replicadb" >> $FIXTURESERVICE
#  echo "  register 0" >> $FIXTURESERVICE
  echo "}" >> $FIXTURESERVICE
#  echo "define service{" >> $FIXTURESERVICE
#  echo "  use em-service-fixture" >> $FIXTURESERVICE
#  echo "  host_name $hostname" >> $FIXTURESERVICE
#  echo "  service_description sensors with no data for 30d" >> $FIXTURESERVICE
#  echo "  check_command check_em_fixture_30d_failures!$replicahost!$replicadb" >> $FIXTURESERVICE
#  echo "  register 0" >> $FIXTURESERVICE
#  echo "}" >> $FIXTURESERVICE

  echo "define service{" >> $FIXTURESERVICE
  echo "  use em-service-fixture" >> $FIXTURESERVICE
  echo "  host_name $hostname" >> $FIXTURESERVICE
  echo "  service_description sensors with no data for over 30d" >> $FIXTURESERVICE
  echo "  check_command check_em_fixture_30d_failures_15p!$replicahost!$replicadb" >> $FIXTURESERVICE
  echo "}" >> $FIXTURESERVICE

#  echo "define service{" >> $FIXTURESERVICE
#  echo "  use em-service-fixture" >> $FIXTURESERVICE
#  echo "  host_name $hostname" >> $FIXTURESERVICE
#  echo "  service_description fixture count" >> $FIXTURESERVICE
#  echo "  check_command check_em_fixture_count!$replicahost!$replicadb" >> $FIXTURESERVICE
#  echo "  register 0" >> $FIXTURESERVICE
#  echo "}" >> $FIXTURESERVICE
#  echo "define service{" >> $FIXTURESERVICE
#  echo "  use em-service-fixture" >> $FIXTURESERVICE
#  echo "  host_name $hostname" >> $FIXTURESERVICE
#  echo "  service_description fixture last_connectivity 7d+ count" >> $FIXTURESERVICE
#  echo "  check_command check_em_fixture_7d_count!$replicahost!$replicadb" >> $FIXTURESERVICE
#  echo "  register 0" >> $FIXTURESERVICE
#  echo "}" >> $FIXTURESERVICE

#  # for gateway count
#  echo "define service{" >> $GATEWAYSERVICE
#  echo "  use em-service-fixture" >> $GATEWAYSERVICE
#  echo "  host_name $hostname" >> $GATEWAYSERVICE
#  echo "  service_description gateway count" >> $GATEWAYSERVICE
#  echo "  check_command check_em_gateway_count!$replicahost!$replicadb" >> $GATEWAYSERVICE
#  echo "  register 0" >> $GATEWAYSERVICE
#  echo "}" >> $GATEWAYSERVICE

  # for gateway failure count
  echo "define service{" >> $GATEWAYSERVICE
  echo "  use em-service-gw" >> $GATEWAYSERVICE
  echo "  host_name $hostname" >> $GATEWAYSERVICE
  echo "  service_description gateways not seen in over 1d" >> $GATEWAYSERVICE
  echo "  check_command check_em_gateway_1d_count!$replicahost!$replicadb" >> $GATEWAYSERVICE
#  echo "  register 0" >> $GATEWAYSERVICE
  echo "}" >> $GATEWAYSERVICE
  echo "define service{" >> $GATEWAYSERVICE
  echo "  use em-service-gw" >> $GATEWAYSERVICE
  echo "  host_name $hostname" >> $GATEWAYSERVICE
  echo "  service_description gateways not seen in over 7d" >> $GATEWAYSERVICE
  echo "  check_command check_em_gateway_7d_count!$replicahost!$replicadb" >> $GATEWAYSERVICE
  echo "}" >> $GATEWAYSERVICE
#  echo "define service{" >> $GATEWAYSERVICE
#  echo "  use em-service-gw" >> $GATEWAYSERVICE
#  echo "  host_name $hostname" >> $GATEWAYSERVICE
#  echo "  service_description gateway last_connectivity 01d+ count" >> $GATEWAYSERVICE
#  echo "  check_command check_em_gateway_1d_count!$replicahost!$replicadb" >> $GATEWAYSERVICE
#  echo "  register 0" >> $GATEWAYSERVICE
#  echo "}" >> $GATEWAYSERVICE
#  echo "define service{" >> $GATEWAYSERVICE
#  echo "  use em-service-gw" >> $GATEWAYSERVICE
#  echo "  host_name $hostname" >> $GATEWAYSERVICE
#  echo "  service_description gateway last_connectivity 07d+ count" >> $GATEWAYSERVICE
#  echo "  check_command check_em_gateway_7d_count!$replicahost!$replicadb" >> $GATEWAYSERVICE
#  echo "  register 0" >> $GATEWAYSERVICE
#  echo "}" >> $GATEWAYSERVICE
#  echo "define service{" >> $GATEWAYSERVICE
#  echo "  use em-service-gw" >> $GATEWAYSERVICE
#  echo "  host_name $hostname" >> $GATEWAYSERVICE
#  echo "  service_description gateway last_connectivity 30d+ count" >> $GATEWAYSERVICE
#  echo "  check_command check_em_gateway_30d_count!$replicahost!$replicadb" >> $GATEWAYSERVICE
#  echo "  register 0" >> $GATEWAYSERVICE
#  echo "}" >> $GATEWAYSERVICE

  # save these to the FS
  echo $last_site > $LASTGROUPSITE
  echo $last_customer > $LASTGROUPCUSTOMER
  echo $site_group_members > $GROUPMEMBERSSITE
  echo $customer_group_members > $GROUPMEMBERSCUSTOMER
  echo $sshhosts > $SSHHOSTS

done

# reading from the FS
last_site=$(cat $LASTGROUPSITE)
last_customer=$(cat $LASTGROUPCUSTOMER)
group_members_site=$(cat $GROUPMEMBERSSITE)
group_members_customer=$(cat $GROUPMEMBERSCUSTOMER)
ssh_hosts=$(cat $SSHHOSTS)

# the last hostgroup

if [ -n "$group_members_site" ] && [ -n "$hostgroup_name" ]; then
  hostgroup_name=`echo $last_site | sed -e 's/ //g' | sed -e 's|&||g' | sed -e 's|(||g' | sed -e 's|)||g' | sed -e 's|\.||g' | sed -e 's|,||g'`
  echo "# SITE hostgroup" >> $OUTPUT
  echo "define hostgroup{" >> $OUTPUT
  echo "  hostgroup_name $hostgroup_name" >> $OUTPUT
  echo "  alias $last_site" >> $OUTPUT
  echo "  members $group_members_site" >> $OUTPUT
  echo "}" >> $OUTPUT
fi

# the last hostgroup
hostgroup_name=`echo $last_customer | sed -e 's/ //g' | sed -e 's|&||g' | sed -e 's|(||g' | sed -e 's|)||g' | sed -e 's|\.||g' | sed -e 's|,||g'`
echo "# CUSTOMER hostgroup" >> $OUTPUT
echo "define hostgroup{" >> $OUTPUT
echo "  hostgroup_name $hostgroup_name" >> $OUTPUT
echo "  alias $last_customer" >> $OUTPUT
echo "  members $group_members_customer" >> $OUTPUT
echo "}" >> $OUTPUT

if [ -n "$ssh_hosts" ]; then
  echo "define servicegroup{" >> $SSHSERVICE
  echo "  servicegroup_name ssh_tunnel_ports" >> $SSHSERVICE
  echo "  members $ssh_hosts" >> $SSHSERVICE
  echo "}" >> $SSHSERVICE
fi

#cleanup
rm -vf $LASTGROUPSITE $LASTGROUPCUSTOMER $GROUPMEMBERSSITE $GROUPMEMBERSCUSTOMER $SSHHOSTS
