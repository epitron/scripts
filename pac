#!/bin/bash

if [ -f "$1" ]; then
  sudoifnotroot pacman -U "$1"
else
  sudoifnotroot pacman -S "$@"
fi
