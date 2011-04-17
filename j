#!/bin/bash


if ! psfind jedit
then
  echo "Launching background jedit..."
  jedit -background > /dev/null
  sleep 8
fi


if [ "`uname`" == "Darwin" ]
then
  # v--- todo: implement the unix shit on macs
  open -a /Applications/jEdit.app "$*"
else
  if [ -d "$*" ]; then
    fullpath="`readlink -e "$*"`" 
    echo "VFSBrowser.browseDirectory(view, \"$fullpath\");" > /tmp/jedit-dir.bsh
    jedit -background -run=/tmp/jedit-dir.bsh > /dev/null
  else
    jedit -background -reuseview "$*" > /dev/null
  fi
fi



