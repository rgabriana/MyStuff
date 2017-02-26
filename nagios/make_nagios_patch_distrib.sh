#!/bin/bash 
###################################################
# Title: make_nagios_patch_distrib
# usage: make_nagios_patch_distrib /tmp/all_em.txt
###################################################

hostname=`echo $LINE | awk -F '|' '{print "EM-"$1}'`
sshenabled=`echo $LINE | awk -F '|' '{print $12}'`
OUTPUT=/etc/nagios3/conf.d/em-p.cfg
PATCHSERVICE=/etc/nagios3/conf.d/em-patch.cfg

