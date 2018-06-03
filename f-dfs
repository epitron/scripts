#!/bin/bash
if [ "$1" == "--help" ]; then
  echo "usage: f <expr> [dirs...]"
  exit
fi

expr="$1"
shift

if [ "$#" == "0" ]; then
  find -L . -xdev | grep -Ei --color=always "$expr"
else
  while (( "$#" )); do
    find -L "$1" -xdev | grep -Ei --color=always "$expr"
    shift
  done
fi
