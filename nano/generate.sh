#!/bin/bash
for file in `ls -1 *.nanorc`; do
  echo "include \"/usr/scripts/nano/$file\""
done