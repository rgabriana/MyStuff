#!/bin/bash
# Simple script that changes the users prompt dependent on the SELINUX status

if  [ "$PS1" ]; then

  # color codes
    red='\033[01;31m'
    green='\033[01;32m'
    blue='\033[00;34m'
    nocolor='\033[0m'
    
  selogo ()

  {
      case $(getenforce) in
      
        Permissive)
          color="$red"$(getenforce)"$nocolor"
        ;;

        Enforcing)
          color="$green"$(getenforce)"$nocolor"
        ;;

        *)
          color="$blue"$(getenforce)"$nocolor"
        ;;
    
       esac

      echo -ne $color
  }

    # show the prompt
    PS1='[SELinux: $(status)]\n[\u@\h: \W]\$ '
    
fi
