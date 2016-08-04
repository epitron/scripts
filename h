#!/usr/bin/env ruby

#
# TODOs:
#  * Aliases (eg: h c => h run rails c)
#

args = ARGV
cmd = ["heroku"]

if args.empty?
  cmd << "--help"
elsif args.include? "--help"
  cmd += args
else
  if args.first == "-p"
    args.shift
    repo = "production"
  else
    repo = "staging"
  end

  cmd << "run" if args.first == "rails"

  cmd += [*args, "-r", repo]
end

p cmd
system *cmd
