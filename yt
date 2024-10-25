#!/usr/bin/env python
################################################################################################
import sys
################################################################################################
reset         = '\033[0m'
bold          = '\033[01m'

disable       = '\033[02m'
underline     = '\033[04m'
reverse       = '\033[07m'
strikethrough = '\033[09m'
invisible     = '\033[08m'

black         = '\033[30m'
red           = '\033[31m'
green         = '\033[32m'
orange        = '\033[33m'
blue          = '\033[34m'
purple        = '\033[35m'
cyan          = '\033[36m'
white         = '\033[37m'

grey          = '\033[90m'
lightred      = '\033[91m'
lightgreen    = '\033[92m'
yellow        = '\033[93m'
lightblue     = '\033[94m'
pink          = '\033[95m'
lightcyan     = '\033[96m'
################################################################################################

try:
  from youtube_search import YoutubeSearch

except ModuleNotFoundError:
  print(f"Missing youtube search support; run '{bold}pip install --user youtube-search{reset}' first.")
  sys.exit(1)

################################################################################################

def help():
  print("usage: yt [options] <query>")
  print()
  print("options:")
  print("   -n <num>   How many results to return")
  print("   -j         JSON output")
  print()

################################################################################################
# Advanced Argparsing

args = sys.argv[1:]

if len(args) == 0 or "--help" in args or "-h" in args:
  help()
  sys.exit(1)

if "-n" in args:
  pos = args.index("-n")
  amount = int(args[pos+1])
  args[pos:pos+2] = []
else:
  amount = None

if "-j" in args:
  args.remove("-j")
  json_mode = True
else:
  json_mode = False

################################################################################################

query = ' '.join(args)

if not json_mode:
  print(f"{grey}* {white}Searching for: {bold}{yellow}{query}{reset}...")

results          = YoutubeSearch(query, max_results=20).to_dict()
numbered_results = [ (i+1, r)   for i, r in enumerate(results) ]

if amount:
  numbered_results = numbered_results[0:amount]

################################################################################################

if json_mode:
  import json

  for n, r in numbered_results:
    print(json.dumps(r))

else:
  for n, r in reversed(numbered_results):
    # r = {'id': 'Zo_jdDGwdg0',
    #      'thumbnails': ['https://i.ytimg.com/vi/Zo_jdDGwdg0/hqdefault.jpg?sqp=-oaymwEjCOADEI4CSFryq4qpAxUIARUAAAAAGAElAADIQj0AgKJDeAE=&rs=AOn4CLDN0XzvVvVswzAx91QUuNMvy5J4qw'],
    #      'title': 'Swans The Sound of Freedom',
    #      'long_desc': None,
    #      'channel': 'Jännis Bunker',
    #      'duration': '4:36',
    #      'views': '932 views',
    #      'url_suffix': '/watch?v=Zo_jdDGwdg0'},

    indent = " " * (len(str(n)) + 2)

    print(f"{lightcyan}{n}. {bold}{white}{r['title']}{reset} {grey}[{white}{r['duration']}{grey}]{reset}")
    print(f"{indent}{grey}by {lightgreen}{r['channel']} {grey}({white}{r['views']}{grey}){reset}")
    print(f"{indent}{bold}{blue}https://youtu.be/{r['id']}{reset}")

    if r['long_desc']:
      print(f"{indent}{r['long_desc']}")

    print()

