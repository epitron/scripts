#!/bin/bash

if [ "$1" == "" ]; then
  ip=8.8.8.8
else
  ip="$1"
fi

ping $ip
