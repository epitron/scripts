if [ "$1" == "" ]; then
  param="$(cb)"
else
  param="$@"
fi

echo "* Playing ${param}..."

fixicon() {
  (sleep 5; seticon MPlayer mpv.png) &
}

if [[ "$param" =~ ^https?:// ]]; then
  echo "  |_ running youtube-dl..."
  url="$(youtube-dl -f best --youtube-skip-dash-manifest -g "$param")"
  echo "  |_ starting mplayer..."
  fixicon
  exec mplayer "$url"
else
  fixicon
  exec mplayer "$param"
fi

