#!/bin/bash

if [ "`uname`" == "Darwin" ]
then
  open -a /Applications/jEdit.app $*
else
  jedit -reuseview $*
fi
