#!/usr/bin/env ruby

CODE_PATHS  = %w[~/work ~/code ~/src]
BIN_PATHS   = ENV["PATH"].split(":")
EXECUTABLES = %w[
  /usr/bin/subl
  /usr/bin/subl3
  ~/opt/sublime/sublime_text
  /opt/sublime/sublime_text
  /Applications/Sublime\ Text\ 2.app/Contents/SharedSupport/bin/subl
]

cmd = EXECUTABLES.map { |fn| File.expand_path fn }.find { |path| File.exists? path }

def which_dir(dir)
  CODE_PATHS.map { |d| File.expand_path d }.each do |path|
    potential_path = File.join(path, dir)
    return potential_path if File.exists? potential_path
  end
  nil
end

def which_bin(bin)
  BIN_PATHS.each do |dir|
    path = File.join(dir, bin)
    return path if File.exists? path
  end
  nil
end


unless cmd
  puts "Error: Sublime Text executable not found."
  puts
  puts "Tried:"
  p EXECUTABLES
  exit 1
end

files = ARGV.map do |arg|
  if File.exists? arg
    arg
  else
    which_dir(arg) || which_bin(arg) || arg
  end
end

exec(cmd, *files)
