#!/bin/bash
[ 
[ $UID -gt "0" ] && echo -e "YOU NEED ADMIN PRIVELEGES TO RUN THIS SCRIPT" && exit
[ -z $@ ] && echo -e "YOU NEED TO SPECIFY THE URL YOU WANT TO DOWNLOAD FROM\n\t\t$0 http/s://name.of.the.website <target_directory>" && exit
[ -z $2 ] && echo -e "YOU NEED TO SPECIFY A TARGET FOLDER\n\t\t$0 http/s://name.of.the.website <target_directory>" && exit
[ ! "$1" =~ ^http ] && echo -e "I DON'T THINK THAT'S a URL\n\t\t$1" && exit

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
