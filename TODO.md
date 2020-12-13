# TODOs

## Dependency Installer

Check for missing dependencies, and prompt the user to install them before the script starts.

eg:

```
require "#{__dir__}/deps.rb"

dependencies do
  gem 'nokogiri'
  gem :http, :epitools
  bin 'ffmpeg'
  bin :getfattr, :setfattr
  py :tvnamer
  pkg 'net-tools'
end
```

(Could use `upm` for installing distro packages... or nixos?)

## General Solution for Embedded Repos

- shallow
- automatic (git hooks?)
- optional (curses radio buttons)
