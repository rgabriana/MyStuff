#!/bin/bash

dwnld () {

wget\
#Logging Options
 --append-output=/var/log/download.script\
 --verbose\
 --rejected-log=/var/log/download.reject\
#Download Options
 --tries=3\
 --continue\
 --progress=dot\
 --show-progress\
 --timeout=360\
 --waitretry=5\
 --prefer-family=IPv4\
 --retry-connrefused\
#Directory Options
 --recursive\
 --no-host-directories\
 --directory-prefix=~/AWIPS2\
#HTTPS Options
 --no-check-certificate
 --no-parent
 --reject "index.htm*"
}

dwnld $1
