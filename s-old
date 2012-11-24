#!/bin/bash

if [ -f /usr/bin/subl ]; then
  CMD=/usr/bin/subl
else
  CMD=~/opt/sublime/sublime_text
fi

if wmls -c -q sublime_text; then
  $CMD "$@" 2>&1 > /dev/null &
else
  $CMD -n "$@" 2>&1 > /dev/null &
fi
