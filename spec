#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CMD="rspec -fd -r $DIR/spec_helper.rb -c"

if which rescue 2> /dev/null
then
  CMD="rescue $CMD"
fi

if [ "$1" == "" ]
then
  FILES=`find . -iname '*_spec.rb'`
  $CMD $FILES
else
  $CMD $*
fi

