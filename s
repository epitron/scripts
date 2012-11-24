#!/usr/bin/env ruby

require 'epitools/wm'
#require 'epitools/path'

cmd = %w[
  /usr/bin/subl
  ~/opt/sublime/sublime_text
  /opt/sublime/sublime_text
].map { |fn| File.expand_path fn }.find { |path| File.exists? path }

raise "Sublime Text executable not found." unless cmd

if WM.current_desktop.windows.find { |win| win.command =~ /sublime_text/ }
  # "$@" 2>&1 > /dev/null &  
  system(cmd, *ARGV)
else
  system(cmd, "-n", *ARGV)
end
