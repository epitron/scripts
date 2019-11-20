#!/usr/bin/env ruby
gem 'slop', "~> 3.6"
require 'slop'
require 'epitools'

Colored.enable!

def parse_options
  opts = Slop.parse(help: true, strict: true) do
    banner "Usage: f [options]"

    on "d",  "dirs", "Search directory names only"
    on "x",  "xdev", "Stay on this device"
    on "L",  "follow", "Follow symbolic links"
    # on "b=", "blong",  "desc", default: ""
  end

  [opts, ARGV]
end

opts, args = parse_options

bins = {
  "bfs" => ["-color"],
  "find" => [],
}

cmd = nil
bins.any? { |bin, args| cmd = [bin, *args] if which(bin) }

if cmd

  cmd += %w[-type d]  if opts.dirs?
  cmd << "-xdev"      if opts.xdev?
  # cmd << "-L"         if opts.follow?
  cmd << "-H"         if opts.follow?

  if args.empty?
    system(*cmd)
    exit
  else
    query = Regexp.new(args.map{|a| Regexp.escape(a) }.join(".*"), Regexp::IGNORECASE)
  end

  # p cmd, query

  # system("#{bin} | grep --color=always -Ei '#{query}'")
  IO.popen(cmd, "rb") do |inp|
    inp.each_line do |l|
      if l =~ query
        puts l.highlight(query)
      end
    end
  end

else
  puts "Couldn't find 'bfs' or 'find'"
end
