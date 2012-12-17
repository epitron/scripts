#!/usr/bin/env ruby

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

begin
  require 'epitools/wm'

  if WM.current_desktop.windows.find { |win| win.command =~ /sublime_text/ }
    system(cmd, *ARGV)
  else
    system(cmd, "-n", *ARGV)
  end
rescue
  system(cmd, "-n", *ARGV)
end
