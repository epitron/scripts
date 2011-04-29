#!/bin/bash

USAGE="usage: f <expr> [dirs...]"

if [ "$#" == "0" ]; then
  echo "$USAGE"
  exit 1
fi

expr="$1"
shift

if [ "$#" == "1" ]; then 
  dirs="."
else
  dirs="$*"
fi

if [ "$#" == "0" ]; then
  find | grep -Ei --color=always "$expr"
else
  while (( "$#" )); do
    find "$1" | grep -Ei --color=always "$expr"
    shift
  done
fi
