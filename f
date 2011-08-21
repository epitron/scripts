#!/bin/bash
if [ "$1" == "--help" ]; then
  echo "usage: f <expr> [dirs...]"
  exit
fi

CMD="find -xdev"
expr="$1"
shift

if [ "$#" == "0" ]; then
  $CMD | grep -Ei --color=always "$expr"
else
  while (( "$#" )); do
    $CMD "$1" | grep -Ei --color=always "$expr"
    shift
  done
fi

