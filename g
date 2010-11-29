#!/usr/bin/env ruby
# encoding: BINARY

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
  require 'colored'
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
  STDERR.puts "Note: You should install the 'colored' gem for extra prettiness.\n"
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
roots = (ARGV.any? ? ARGV : ['.']).
        map{ |path| Pathname(path) }.
        select { |path| path.exist? || STDERR.puts("Error: #{path} doesn't exist") }
#################################################################


#################################################################
## Grep files/display results
def breadth_first_file_scan(root, &block)
  if root.file?
    yield root 
    return
  end

  files = []
  dirs = []
  root.children.sort.each do |entry|
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
  open(path, "rb") do |f|
    f.each_with_index do |line, n|
      yield(line,n+1) if line =~ query
    end
  end
end

roots.each do |root|
  begin

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

  rescue Interrupt
    # eat ^C
    exit(1)
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

