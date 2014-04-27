#!/usr/bin/env ruby

def which(bin)
  ENV["PATH"].split(":").each do |dir|
    path = File.join(dir, bin)
    return path if File.exists? path
  end
end


executables = %w[
  /usr/bin/subl
  ~/opt/sublime/sublime_text
  /opt/sublime/sublime_text
  /Applications/Sublime\ Text\ 2.app/Contents/SharedSupport/bin/subl
]

cmd = executables.map { |fn| File.expand_path fn }.find { |path| File.exists? path }

unless cmd
  puts "Error: Sublime Text executable not found."
  puts
  puts "Tried:"
  p executables
  exit 1
end

# begin
#   require 'epitools/wm'

#   if WM.current_desktop.windows.find { |win| win.command =~ /sublime_text/ }
#     system(cmd, *ARGV)
#   else
#     system(cmd, "-n", *ARGV)
#   end
# rescue
#   system(cmd, "-n", *ARGV)
# end


files = ARGV.map do |arg|
  if File.exists? arg
    arg
  elsif found = which(arg)
    found
  end
end


system(cmd, *files)