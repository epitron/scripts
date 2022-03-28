#!/usr/bin/env ruby
# encoding: BINARY

#################################################################
## For author info, scroll to the end of this file.
#################################################################

#################################################################
## Load Modules
require 'rubygems'
require 'set'
require 'epitools'
#################################################################


#################################################################
## Settings
MAX_LINE_LENGTH  = 1000
IGNORE_PATHS     = Set.new([".svn", ".git", "CVS"])

configfile = Path["~/.grc.json"]
config = configfile.parse
config["download_path"] ||= "~/Downloads"
  DOWNLOAD_PATH    = Path[config["download_path"]]
configfile.write(config.to_json)

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
        map{ |path| Path[path] }.
        select { |path| path.exists? || STDERR.puts("Error: #{path} doesn't exist") }
#################################################################


#################################################################
## Grep files/display results
def old_breadth_first_file_scan(root, &block)
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
  dirs = dirs.select { |dir| not dir =~ %r{/\.{1,2}/} }

  # strip #{root} from paths
  dirs, files = [dirs,files].map do |list|
    list.map { |f| f[root.size..-1] }
  end
  
  [dirs, files]
end


$visited = {} # visited paths, to avoid symlink-loops

def breadth_first_scan(root, &block)
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


def grep_file(path, query, &block)
  open(path, "rb") do |f|
    f.each_with_index do |line, n|
      if line =~ query
        yield(line,n+1)
      end
    end
  end
rescue => e
  #STDERR.puts e  
end

lesspipe do |less|
  
  roots.each do |root|
    begin
  
      breadth_first_scan(root.to_s) do |root, path|
        unless path[-1] == ?/
          grep_file(File.join(root,path), query) do |line,n|
            less.puts "#{path.magenta} #{n.to_s.green}#{":".blue}#{line.highlight(query)}"
          end
        end
      end
  
    rescue Interrupt
      # eat ^C
      exit(1)
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

