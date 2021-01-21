#!/usr/bin/env ruby

args = ARGV

if args.empty?
  path = Dir.pwd
else
  path = File.expand_path args.first
end

#
# To visit a specific path, run: eaglemode -visit ::FS::::home::user::some.pdf
#
panel = "::FS::#{path.gsub("/", "::")}"

cmd = ["eaglemode", "-visit", panel]
# p [path, cmd]
fork { exec *cmd }