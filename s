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

bin = EXECUTABLES.map { |fn| File.expand_path fn }.find { |path| File.exists? path }

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

def sublime_on_current_desktop?
  WM.current_desktop.windows.find { |w| w.title["Sublime Text"] }
end

unless bin
  puts "Error: Sublime Text executable not found."
  puts
  puts "Tried:"
  p EXECUTABLES
  exit 1
end

require 'epitools/wm'

opts, args = ARGV.partition { |arg| arg[/^--?\w/] }

files = args.map do |arg|
  if File.exists? arg
    arg
  else
    which_dir(arg) || which_bin(arg) || arg
  end
end

opts << "-n" unless opts.include?("-n") or sublime_on_current_desktop?

# p bin: bin, opts: opts, files: files

cmd = [bin, *opts, *files]
exec *cmd
