#!/bin/sh

if type setopt &> /dev/null; then 
  CURRENT_SHELL=zsh
else
  if [ -n "$BASH" ]; then
    CURRENT_SHELL=bash
  elif help | grep "Built-in commands:" > /dev/null; then
    CURRENT_SHELL=busybox
  else
    echo $SHELL unknown
    ps | grep $$
    CURRENT_SHELL=unknown
  fi
fi

export CURRENT_SHELL

echo Current shell: $CURRENT_SHELL
