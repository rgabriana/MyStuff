#!/bin/bash
#####################################
# Simple Script to runthe stig checks
#####################################
# font check
[ -x fonts ] && source fonts
# Root check
[ $UID != "0" ] && echo -e "$redfont You need Admin Priveleges to run this script $resetfont" && exit
# STIG check 
[ ! -x STIG7CHECKS ] && echo -e "cannot find STIG7CHECKS file or it is not executable please verify" && exit
source STIG7CHECKS

RHEL-07-010010
