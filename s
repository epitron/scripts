#!/usr/bin/env ruby
#############################################################################
CODE_PATHS   = %w[~/work ~/code ~/src]
BIN_PATHS    = ENV["PATH"].split(":")
SUBLIME_BINS = %w[
  subl
  subl3
  ~/opt/sublime/sublime_text
  /opt/sublime/sublime_text
  /Applications/Sublime\ Text\ 2.app/Contents/SharedSupport/bin/subl
]
OTHER_EDITORS = %w[
  nano
  vim
  leafpad
  mousepad
]
#############################################################################

def which_dir(dir)
  if dir == "scripts"
    sd = File.expand_path("~/scripts")
    if File.directory?(sd)
      return sd
    end
  else
    CODE_PATHS.map { |d| File.expand_path d }.each do |path|
      potential_path = File.join(path, dir)
      return potential_path if File.exists? potential_path
    end
  end
  nil
end

def which_bin(bin)
  BIN_PATHS.each do |dir|
    path = File.join(dir, bin)
    return path if File.file? path
  end
  nil
end

def find_bin(bins)
  bins.each do |fn| 
    if fn[%r{[~/]}] 
      fn = File.expand_path(fn) 
      return fn if File.exists? fn
    else
      if bin = which_bin(fn)
        return bin
      end
    end
  end
  nil
end
    

def sublime_on_current_desktop?
  require 'epitools/wm'
  WM.current_desktop.windows.find { |w| w.title["Sublime Text"] }
end

#############################################################################

opts, args = ARGV.partition { |arg| arg[/^--?\w/] }

files = args.map do |arg|
  if File.exists? arg
    arg
  else
    which_dir(arg) || which_bin(arg) || arg
  end
end

if sublime_bin = find_bin(SUBLIME_BINS)
  opts << "-n" unless opts.include?("-n") or sublime_on_current_desktop?
  cmd = [sublime_bin, *opts, *files]
  fork { IO.popen(cmd, :err=>[:child, :out]) { |io| io.read } }
elsif bin = find_bin(OTHER_EDITORS)
  cmd = [bin, *files]
  exec *cmd
else
  puts "Error: Couldn't find an editor."
  exit 1
end

