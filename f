#!/usr/bin/env ruby
#################################################################
## For author info, scroll to the end of this file.
#################################################################


#################################################################
## Load Modules
require 'rubygems' 
require 'pathname'
require 'pp'
require 'epitools'
#################################################################


#################################################################
## Globals
if ARGV.any?{|arg| arg == "-v"}
  ARGV.remove_if{|arg| arg == "-v"}
  $verbose = true
else
  $verbose = false
end
#################################################################



#################################################################
## Display Help (if requested)
if ["--help", "-h"].include?(ARGV[0])
  puts DATA.read
  exit
end
#################################################################



#################################################################
## Old path scanner (Pathname is SLOWW)

def breadth_first_scan_old(root, &block)
  if root.file?
    yield root
    return
  end

  children = Pathname(root).children.sort
  begin
    children.each { |child| yield child } # breadth
    children.each { |child| breadth_first_scan(child, &block) if child.directory? }
  rescue Errno::EACCES, Errno::EPERM => e
    STDERR.puts("Error: #{e}".red)
  end
end

#################################################################



#################################################################
## NEW path scanner

def slashed(path)
  path[-1] == ?/ ? path : (path + "/") 
end

def listdir(root)
  root = slashed(root)
  
  dirs = Dir.glob("#{root}*/", File::FNM_DOTMATCH)
  files = Dir.glob("#{root}*", File::FNM_DOTMATCH)

  dirs_without_slashes = dirs.map{|dir| dir[0...-1]} 
  files = files - dirs_without_slashes # remove dirs from file list

  # drop the "." and ".." dirs
  dirs = dirs.select { |dir| not dir =~ %r[/\.{1,2}/] }

  # strip #{root} from paths
  dirs, files = [dirs,files].map do |list|
    list.map { |f| f[root.size..-1] }
  end
  
  [dirs, files]
end


$visited = {} # visited paths, to avoid symlink-loops

def breadth_first_scan(root, &block)
  puts "=== ".light_black + root.light_cyan + " ===".light_black if $verbose

  root = slashed(root)
  
  dirs, files = listdir(root)
  path_id = File.lstat(root).ino
  
  if seenpath = $visited[path_id]
    STDERR.puts "*** WARNING: Already seen #{root.inspect} as #{seenpath.inspect}".red if $verbose
  else
    $visited[path_id] = root
    
    dirs.each  { |f| yield root, f }
    files.each { |f| yield root, f }
    
    for dir in dirs
      breadth_first_scan(root+dir, &block)
    end
  end
end

#################################################################



#################################################################
## MAIN

if $0 == __FILE__

  # Separate options from commmandline args
  opts = ARGV.select{|arg| arg =~ /^-\w$/}
  args = ARGV - opts

  # Handle args
  case args.size
    when 0
      query = ''
      roots = ['.']
    when 1
      if args.first =~ %r{(^/|/$|^\./)} #and File.directory?(ARGV.first)
        query = ''
        roots = [args.first]
      else
        query = args.first
        roots = ['.']
      end
    else
      query = args.shift
      roots = args
  end

  # Handle one-letter options (eg: -a)
  for opt in opts
    case opt
      when '-a'
        roots.unshift query
        query = ''
      when '-v'
        $verbose = true
    end
  end

  
  # Matcher
  orig_query = query
  query = Regexp.new( Regexp.escape( query ), Regexp::IGNORECASE )

  # Ignore bad path arguments
  roots = roots.select do |path|
    File.exists?(path) || STDERR.puts("Error: #{path} doesn't exist")
  end

  # Search!
  lesspipe(:wrap=>true) do |less|

    roots.each do |root|
      begin
        breadth_first_scan(root) do |dirname, filename|

          if orig_query['/']
            # search in the full path if the user put a '/' in the query
            path = dirname + filename
            less.puts path.highlight(query) if path =~ query
          else
            # search in the filenames only
            less.puts dirname+filename.highlight(query) if filename =~ query
          end
        
        end
      rescue Interrupt
        # eat ^C's
        exit(1)
      end
    end
  
  end

end

#################################################################



#################################################################
## Help message (will be put in the DATA array)
__END__
"f" (c) 2002-2011 by Chris Gahan (chris@ill-logic.com)

Usage:
  f                         => recursively list all files in current directory
  f <search string>         => recursively list all files in current directory
                               containing <search string>
  f <search string> <paths> => recursively list all files in <paths>
                               containing <search string>
  f -a <paths>              => show all files in paths
  f -v [...]                => verbose mode (warns if there are symlink loops)

(Note: To colorize the search results, install the "colorize" gem.)

