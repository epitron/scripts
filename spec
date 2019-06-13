#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CMD="rspec -fd -r $DIR/spec_helper.rb -c"

if [ "$1" == "--help" ]; then
  echo "usage:"
  echo "  spec [options] <spec file>.rb [<substring to match against spec names>]"
  echo
  echo "options:"
  echo "  -r     pry-rescue failing specs"
  echo
  echo "  PLUS: all standard rspec options (see rspec --help)"
  echo
  exit
fi

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
  if [ "$2" == "" ]; then
    $CMD $*
  else
    $CMD -e "$2" "$1"
  fi
fi
