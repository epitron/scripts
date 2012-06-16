#!/bin/bash
if [[ "$1" == "" ]]; then
  pacman -Q
else
  pacman -Ql "$*"
fi

