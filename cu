#!/bin/bash
if [ "$*" == "" ]; then
  DIRS=.
else
  DIRS="$*"
fi

for i in $DIRS; do
echo
echo -n "=== Updating $i "
pushd $i > /dev/null
if [ -d .git ]; then
        echo "(git pull) ==="
        echo
	git pull
elif [ -d .svn ]; then
        echo "(svn update) ==="
        echo
	svn update
elif [ -d .hg ]; then
        echo "(hg {pull,update}) ==="
        echo
	hg pull && hg update
elif [ -d CVS ]; then
        echo "(cvs update) ==="
        echo
	cvs update -dP
else
	echo "No repo found..."
fi
popd > /dev/null
echo
done
