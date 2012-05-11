#!/bin/bash

CMD=~/opt/sublime/sublime_text

if wmls -c -q sublime_text; then
  $CMD "$@" 2>&1 > /dev/null &
else
  $CMD -n "$@" 2>&1 > /dev/null &
fi
