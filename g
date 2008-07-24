#!/usr/bin/env ruby
#################################################################
## For author info, scroll to the end of this file.
#################################################################

#################################################################
## Load Modules
require 'pathname'
require 'set'
#################################################################


#################################################################
## Settings
MAX_LINE_LENGTH  = 1000
IGNORE_PATHS     = Set.new([".svn", ".git", "CVS"])
#################################################################


#################################################################
## Load the colorize gem, and define the "hilite" function
begin
  require 'rubygems' 
  require 'colorize'
  # Colourized hilite...
  class String
    def hilite(query)
      if size > MAX_LINE_LENGTH
        line = self[0..MAX_LINE_LENGTH]
        extra = " [...plus #{size - MAX_LINE_LENGTH} more bytes...]".red 
      else
        line = self
        extra = ""
      end
      line.to_s.gsub(/(.*)(#{query})(.*)/) { $1 + $2.black.on_yellow + $3 } + extra
    end
  end
rescue LoadError
  STDERR.puts "Note: You should install the 'colorize' gem for extra prettiness.\n"
  # Define black & white stubs to replace colorized methods...
  class String
    def hilite(query)
      if size > MAX_LINE_LENGTH
        line = self[0..MAX_LINE_LENGTH]
        extra = " [...plus #{size - MAX_LINE_LENGTH} more bytes...]"
      else
        line = self
        extra = ""
      end
      line + extra
    end
    %w(magenta blue green).each do |name|
      define_method(name, proc { self })
    end
  end
end
#################################################################


#################################################################
## Display Help (if requested)
if ["--help", "-h"].include?(ARGV[0]) or ARGV.size == 0
  puts DATA.read
  exit
end
#################################################################


#################################################################
## Parse Commandline
query = Regexp.new(Regexp.escape(ARGV.shift), Regexp::IGNORECASE)
roots = (ARGV.any? ? ARGV : ['.']).select { |path| File.directory? path }
#################################################################


#################################################################
## Grep files/display results
def breadth_first_file_scan(root, &block)
  files = []
  dirs = []
  Pathname(root).children.sort.each do |entry|
    if entry.directory?
      dirs << entry unless IGNORE_PATHS.include? entry.basename.to_s
    else
      files << entry
    end
  end

  files.each { |file| yield file } # files
  dirs.each { |dir| breadth_first_file_scan(dir, &block) }
end

def grep_file(path, query, &block)
  path.open do |f|
    f.each_with_index do |line,n|
      yield(line,n+1) if line =~ query
    end
  end
end

roots.each do |root|
  breadth_first_file_scan(root) do |path|
    if path.file?
      grep_file(path, query) do |line,n|
        puts [
	  path.to_s.magenta,   # pathname
          " ", 
          n.to_s.green,        # line number
          ":".blue, 
          line.hilite(query)   # line
        ].join
      end
    end
  end
end
#################################################################


#################################################################
## Help message (will be put in the DATA array)
__END__
"g" (c) 2002-2008 by Chris Gahan (chris@ill-logic.com)

Usage:
  g <search string>         => recursively grep all files in current directory
                               containing <search string>
  g <search string> <paths> => recursively grep all files in <paths>
                               containing <search string>

(Note: To colorize the search results, install the "colorize" gem.)

