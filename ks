#!/bin/bash

#
# PROGRAM: 
#     ks (Killsearch v0.1 by Chris Gahan)
#
# DESCRIPTION:
#     Killsearch will search your processes for a substring, and kill all
# matching processes with the specified signal (default = -9).
#

echo

if [[ $* == "" ]]
then
   echo "Usage: ks [kill SIGNAL] [grep pattern]"
else

   KILLSIG="-9"
   if [[ ${1:0:1} == "-" ]]
   then

      if [[ $2 == "" ]]
      then
         echo "You need more parameters bitch!"
         exit
      else
         KILLSIG=$1
         shift
         SEARCHFOR="$*"
      fi
      
   else
      SEARCHFOR="$*"
   fi

#   echo "searchfor = $SEARCHFOR, killparam = $KILLPARAM, ps = $PSCMD"

   echo "Processes to kill..."
   echo "----------------------------------------------------------------"

   if psfind "$SEARCHFOR" | grep -v $0
   then
      echo "----------------------------------------------------------------"
      echo
      echo -n "Kill these processes with signal '$KILLSIG'? (Y/n) "
      read INPUT

      if [[ $INPUT == "n" || $INPUT == "N" ]]
      then
         echo "Not killing anything."
      else
         echo
         echo "Killing processes..."
         kill $KILLSIG `psfind "$SEARCHFOR" | grep -v $0 | awk '{print $1}'`
      fi

   else
      echo "Found NOTHING!"
   fi

fi

echo
