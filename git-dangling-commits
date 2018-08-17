#!/bin/bash
git log --graph --oneline --decorate --all $( git fsck --no-reflog | awk '/dangling commit/ {print $3}' )
