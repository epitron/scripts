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

bins = {
  "bfs" => ["-color"],
  "find" => [],
}

cmd = nil
bins.any? { |bin, args| cmd = [bin, *args] if which(bin) }

if cmd

  query = Regexp.new(args.map{|a| Regexp.escape(a) }.join(".*"), Regexp::IGNORECASE)

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
