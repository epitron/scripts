#!/bin/bash
CMD="rspec -fs -c"

if [ "$1" == "" ]
then
  FILES=`find . -iname '*_spec.rb'`
  $CMD $FILES
else
  $CMD $*
fi

