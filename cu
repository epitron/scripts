if [ -d .svn ]
then
        echo "=== SVN Updating... ==="
	svn update
else
        echo "=== CVS Updating... ==="
	cvs update -dP
fi
