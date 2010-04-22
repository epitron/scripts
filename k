if [ "$*" == "" ]
then
  konqueror --profile filemanagement "$HOME"
else
  konqueror --profile filemanagement "$*"
fi
