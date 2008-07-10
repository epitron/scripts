if [ -d .svn ]
then
        echo "=== SVN Updating... ==="
	svn update
elif [ -d .git ]
then
        echo "=== Git Pulling... ==="
	git pull
elif [ -d CVS ]
then
        echo "=== CVS Updating... ==="
	cvs update -dP
else
	echo "No repo found..."
fi
