#!/usr/bin/env ruby
gem 'slop', "~> 3.6"
require 'slop'
require 'epitools'

def parse_options
  opts = Slop.parse(help: true, strict: true) do
    banner "Usage: f [options]"

    # on "a",  "along",  "desc"
    # on "b=", "blong",  "desc", default: ""
  end

  [opts, ARGV]
end

opts, args = parse_options

if bin = which("bfs", "find")
  query = args.join(" ")
  system("#{bin} | grep --color=always -Ei '#{query}'")
else
  puts "Couldn't find 'bfs' or 'find'"
end