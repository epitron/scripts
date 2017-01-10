if [ "$1" == "" ]; then
  pip list | less -S
else
  pip show -v -f $1 | less -S
fi
