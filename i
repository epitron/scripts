if [ "$1" == "" ]
then
	echo "Init scripts:"
	echo "============================="
	ls /etc/init.d
else
	if [ "$2" == "" ]
	then
		CMD="restart"
	else
		CMD="$2"
	fi

	/etc/init.d/$1 $CMD
fi
