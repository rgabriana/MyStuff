#!/bin/bash

red='\[\033[0;31m\]'
green='\[\033[0;32m\]'
blue='\[\033[0;34m\]'
nocolor='\[\033[0m\]'

case $(getenforce) in 
  Permissive)
  color=$red
  ;;

  Enforcing)
  color=$green
  ;;

  *)
  color=$blue
  ;;
esac

if  [ "$PS1" ]; then 
  PS1="[\u@\h:$color\$(getenforce)$nocolor \W]\\$ "
fi
