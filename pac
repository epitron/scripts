#!/bin/bash

if [ "$1" == "" ]; then
  if [ -f *.pkg.tar.xz ]; then
    # install it
    sudoifnotroot pacman -U "`ls *.pkg.tar.xz|tail -n1`"
    exit
  fi
fi

if [ -f "$1" ]; then
  sudoifnotroot pacman -U "$1"
else
  sudoifnotroot pacman -S "$@"
fi
