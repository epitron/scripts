#!/bin/bash

if [ "$1" == "--help" ]; then
  echo "usage: gp <commit message>"
  echo
  echo ' "git commit" all modified files, then "git push" if successful.'
  echo
  exit 1
fi

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
