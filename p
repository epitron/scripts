#!/bin/bash

if [ "$i" == "" ]; then
  ip=8.8.8.8
else
  ip="$1"
fi

ping $ip
