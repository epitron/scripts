#!/bin/bash

if [ "$1" == "" ]; then
  LATEST_PKG="`ls -tr *.pkg.tar.{xz,gz,bz2}|tail -n1`"

  if [ -f "$LATEST_PKG" ]; then
    # install it
    sudoifnotroot pacman -U "$LATEST_PKG"
    exit
  fi
fi

if [ -f "$1" ]; then
  sudoifnotroot pacman -U "$1"
else
  sudoifnotroot /usr/bin/pacman -S -- "$@"
fi
