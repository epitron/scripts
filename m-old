#!/bin/bash

if [ -f "$1" ]; then
  VFOPTS="`getfattr --match=.vf -d --only-values "$1"`"
fi

if [ "$VFOPTS" == "" ]; then
  exec mpv "$@"
else
  exec mpv -vf $VFOPTS "$@"
fi
