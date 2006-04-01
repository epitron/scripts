if (( $# < 1 ))
then
  echo "Usage: f [search pattern] [paths to search]"
fi

WORD='*'$1'*'
shift

if (( $# < 1 ))
then
  PARAMS=.
else
  PARAMS="$*"
fi

echo "+ Searching for $WORD in $PARAMS"

find $PARAMS -iname "$WORD"
