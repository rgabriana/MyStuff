#!/bin/bash
# Simple script that changes the users prompt dependent on the SELINUX status

if  [ "$PS1" ]; then 
  selogo () {
    red='\[\033[0;31m\]'
    green='\[\033[0;32m\]'
    blue='\[\033[0;34m\]'
    nocolor='\[\033[0m\]'

      case $(getenforce) in 
        Permissive)
          color=$redPermissive$nocolor
        ;;

        Enforcing)
          color=$greenEnforcing$nocolor
        ;;

        *)
          color=$blueUNKNOWN$nocolor
        ;;
    
      esac
  
  }

  PS1="[\u@\h:$(selogo) \W]\\$ "

fi
