#!/bin/bash
if [ -z "$1" ]; then
  param="$(cb)"
else
  param="$@"
fi

#opts=""
#param=""

#while (( $# > 0 )); do
#  if [[ "$1" =~ ^-\w ]]; then
#    opts="$opts $1"
#  else
#    param="$param $1"
#  fi
#  shift
#done

echo "* Playing ${param}"

fixicon() {
  (sleep 5; seticon MPlayer mpv.png) &
}

#CMD="mplayer -use-filename-title"

if [ -z "$PLAYER" ]; then
  PLAYER="mplayer"
fi

if [[ "$param" =~ ^https?:// ]]; then
  if [[ "$param" =~ /watch\?v=([^&]+) ]]; then
    param="https://youtu.be/${BASH_REMATCH[1]}"
  elif [[ "$param" =~ invidious.+/(.+) ]]; then
    param="https://youtu.be/${BASH_REMATCH[1]}"
  fi
  echo "  |_ youtube-dling $param"

  url="$(youtube-dl -f best --youtube-skip-dash-manifest -g "$param")"
  echo "  |_ starting $PLAYER"

  fixicon
  exec $PLAYER "$url"
else
  fixicon
  exec $PLAYER "$param"
fi

