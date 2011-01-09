#!/bin/bash
if [ -d .git ]; then
        echo "=== git pull ==="
	git pull
elif [ -d .svn ]; then
        echo "=== svn update ==="
	svn update
elif [ -d .hg ]; then
        echo "=== hg pull, hg update ==="
	hg pull && hg update
elif [ -d CVS ]; then
        echo "=== cvs update ==="
	cvs update -dP
else
	echo "No repo found..."
fi
