#!/bin/bash

echo "Committing"
echo "------------------------------"

if [ "$*" == "" ]
then
  git commit -a -v
else
  git commit -a -m "$*"
fi
RESULT=$?

echo

if [ $RESULT -ne 0 ]
then
  echo Commit failed
else
  echo "Pushing"
  echo "------------------------------"
  git push
fi
