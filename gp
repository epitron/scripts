#!/bin/bash

if [ "$*" == "" ]
then
  git commit -a -v
else
  git commit -a -m "$*"
fi

echo

if [ $? -ne 0 ]
then
  echo Commit failed
else
  echo "Commit success -- pushing"
  git push
fi
