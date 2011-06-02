#!/bin/bash

USAGE="usage: f <expr> [dirs...]"

expr="$1"
shift

if [ "$#" == "0" ]; then
  find | grep -Ei --color=always "$expr"
else
  while (( "$#" )); do
    find "$1" | grep -Ei --color=always "$expr"
    shift
  done
fi

