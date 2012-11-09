#!/bin/bash
if [ "$1" == "--help" ]; then
  echo "usage: f <expr> [dirs...]"
  exit
fi

if [ $(uname -s | grep -E '(Darwin|BSD)') ]; then
  ARGS="-x"
else
  ARGS="-xdev"
fi

expr="$1"
shift

if [ "$#" == "0" ]; then
  find . $ARGS | grep -Ei --color=always "$expr"
else
  while (( "$#" )); do
    find "$1" $ARGS | grep -Ei --color=always "$expr"
    shift
  done
fi
