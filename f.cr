#!/usr/bin/env ruby
#################################################################
## For author info, scroll to the end of this file.
#################################################################

#################################################################
## Globals
if ARGV.delete("-v")
  $verbose = true
else
  $verbose = false
end
#################################################################

#################################################################
## Display Help (if requested)
if ["--help", "-h"].includes?(ARGV[0]?)
  puts %{"f" (c) 2002-2015 by Chris Gahan (chris@ill-logic.com)

Usage:
  f                         => recursively list all files in current directory
  f <search string>         => recursively list all files in current directory
                               containing <search string>
  f <search string> <paths> => recursively list all files in <paths>
                               containing <search string>
  f -a <paths>              => show all files in paths
  f -v [...]                => verbose mode (warns if there are symlink loops)
}

  exit
end
#################################################################


#################################################################
## NEW path scanner

def slashed(path)
  path[-1] == '/' ? path : (path + "/") 
end

def listdir(root)
  root = slashed(root)

  dirs  = [] of String
  files = [] of String

  Dir.list(root) do |fn, type|
    if type == Dir::Type::DIR
      next if fn == "." || fn == ".."
      dirs << fn
    else
      files << fn
    end
  end

  [dirs, files]
end

$visited = {} of UInt64 => String # visited paths, to avoid symlink-loops

def breadth_first_scan(root, &block : (String, String) -> )
  # puts "=== #{root} ===" if $verbose

  root        = slashed(root)
  dirs, files = listdir(root) 
  path_id     = File.lstat(root).ino
  
  # p [root, path_id]
  unless $visited[path_id]?
    $visited[path_id] = root
    
    dirs.each  { |f| yield root, f }
    files.each { |f| yield root, f }
    
    dirs.each do |dir|
      breadth_first_scan(root+dir, &block)
    end
  end
end

#################################################################

class String
  def highlight(query)
    gsub(query) { |str| "\e[33m\e[1m#{str}\e[0m" }
  end
end

#################################################################
## MAIN

# Separate options from commmandline args
opts, args = ARGV.partition{|arg| arg =~ /^-\w$/}

# Handle args
case args.size
  when 0
    query = ""
    roots = ["."]
  when 1
    if args.first =~ %r{(^/|/$|^\./)} #and File.directory?(ARGV.first)
      query = ""
      roots = [args.first]
    else
      query = args.first
      roots = ["."]
    end
  else
    query = args.shift
    roots = args
end

# Handle one-letter options (eg: -a)
opts.each do |opt|
  case opt
  when "-a"
    roots.unshift query
    query = ""
  when "-v"
    $verbose = true
  end
end


# Matches

re = Regex.new( Regex.escape( query ), Regex::IGNORE_CASE )
has_query = !query.empty?

# Ignore bad path arguments
roots = roots.select do |path|
  File.exists?(path) || STDERR.puts("Error: #{path} doesn't exist")
end

# Search!
# lesspipe(:wrap=>true) do |less|

roots.each do |root|
  breadth_first_scan(root) do |dirname, filename|

    if has_query
      if query["/"]
        # search the full path if the user put a '/' in the query
        path = dirname + filename
        if path =~ re
          puts path.highlight(re)
        end
      else
        # search in the filenames only
        if filename =~ re
          puts dirname + filename.highlight(re) 
        end
      end
    else
      puts dirname + filename
    end

  end
end

#################################################################
