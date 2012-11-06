#!/bin/bash
if [ "$1" == "--help" ]; then
  echo "usage: f <expr> [dirs...]"
  exit
fi

if [ $(uname -s | grep -E '(Darwin|BSD)') ]; then
  CMD="find -x"
else
  CMD="find -xdev"
fi

expr="$1"
shift

if [ "$#" == "0" ]; then
  $CMD . | grep -Ei --color=always "$expr"
else
  while (( "$#" )); do
    $CMD "$1" | grep -Ei --color=always "$expr"
    shift
  done
fi

