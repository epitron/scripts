#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CMD="rspec -fd -r $DIR/spec_helper.rb -c"

if [ "$1" == "-r" ]; then
  shift
  if which rescue 2> /dev/null
  then
    CMD="rescue $CMD"
  else
    echo "pry-rescue is not installed."
    exit 1
  fi
fi

if [ "$1" == "" ]
then
  FILES=`find . -iname '*_spec.rb'`
  $CMD $FILES
else
  $CMD $*
fi

