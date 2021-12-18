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

CMD="mplayer -use-filename-title -fs"

if [ -z "$PLAYER" ]; then
  PLAYER="$CMD"
fi

if [[ "$param" =~ ^https?:// ]]; then
  if [[ "$param" =~ \.(mp4|mkv|avi|ogv|ogm)$ ]]; then
    url="$(echo "$param" | sed s/8888/8887/)"
    echo "  |_ url: $url"
  else
    if [[ "$param" =~ /watch\?v=([^&]+) ]]; then
      param="https://youtu.be/${BASH_REMATCH[1]}"
    elif [[ "$param" =~ invidious.+/(.+) ]]; then
      param="https://youtu.be/${BASH_REMATCH[1]}"
    fi
    echo "  |_ youtube-dling $param"

    url="$(youtube-dl -f best --youtube-skip-dash-manifest -g "$param")"
  fi

  echo "  |_ starting $PLAYER"
  fixicon
  exec $PLAYER "$url"
else
  fixicon
  exec $PLAYER "$param"
fi

