#!/bin/bash -x
##################################################
# Title: GX440_parse.sh
# Usage: \
# bash GX440_parse.sh /etc/nagios/airlink.data/EM-*
##################################################

ROOT_ID=0

if [ "$UID" -ne "$ROOT_ID" ]; then

  echo "You need root priveleges to run this program" 
  exit 1

fi

set -e

tmp1=$(mktemp)
tmp2=$(mktemp)
OUTPUT=/tmp/airlink_data
#OUTPUT=~/airlink_data

Q=`grep ?$ $1 | wc -l`
A=`grep 'OK\|ERROR' $1 | wc -l`
size=`ls -l $1 | awk -F " " '{print $5}'`

# Check to see if the file is empty
if (( $size == 0 || "$Q" != "$A")); then
  echo "$1: file size: $size $Q/$A Bad file moving on"
  rm -vf $tmp1 $tmp2
  exit
fi
echo $1 | awk -F '/' '{print $NF}' > $tmp1 # Add the EM's name into the report

awk 'length($0) > 0' $1 >> $tmp1  # Remove the blank lines

grep -v "?" $tmp1 > $tmp2 # Remove the unneeded entries

sed -i -e 's/OK/\|/g' -e 's/ERROR/\|/g' $tmp2 #change the delimiter

cat $tmp2 |tr '\n' ' ' >> $OUTPUT # Create the list

sed -i -e 's/ | /|/g' -e 's/| /|/g' -e 's/ |/|/g' $OUTPUT

echo "" >> $OUTPUT # Add a character return at the end of the entry.

#Cleanup

rm -f $tmp1 $tmp2
