#!/usr/bin/env ruby
###############################################################################
gem 'slop', "~> 3.6"
require 'slop'
require 'epitools/rash'
require 'epitools/path'
require 'epitools/colored'
###############################################################################

TYPE_INFO = [
  [:code,    /\.(rb|c|c++|cpp|py|sh|nim|pl|awk|go|php)$/i, :white],
  [:music,   /\.(mp3|ogg|m4a)$/i,                          :purple],
  [:video,   /\.(mp4|mkv|avi|m4v)$/i,                      :light_purple],
  [:sub,     /\.(srt|idx|sub)$/i,                          :grey],
  [:image,   /\.(jpe?g|bmp|png)$/i,                        :green],
  [:doc,     /\.(txt|pdf)$/i,                              :light_white],
  [:dotfile, /^\../i,                                      :grey],
  [:archive, /\.(zip|rar|arj|pk3|deb|tar\.(?:gz|bz2|xz)|gem)$/i, :light_yellow]
]

FILENAME2COLOR = Rash.new TYPE_INFO.map { |name, regex, color| [regex, color] }
FILENAME2TYPE  = Rash.new TYPE_INFO.map { |name, regex, color| [regex, name] }

ARG2TYPE = Rash.new({
  /^(code|source|src)$/   => :code,
  /^(music|audio)$/       => :music,
  /^videos?$/             => :video,
  /^(subs?)$/             => :sub,
  /^(image?s|pics?|pix)$/ => :image,
  /^(text|docs?)$/        => :doc,
  /^(archives?|zip)$/     => :archive,
  /^(dir|directory)$/     => :dir,
  /^(bin|exe|program)s?$/ => :bin,
  /^dotfiles?$/           => :dotfile,
})

SIZE_COLORS = Rash.new(
              0...100 => :grey,
            100...1_000 => :blue,
          1_000...1_000_000 => :light_blue,
      1_000_000...1_000_000_000 => :light_cyan,
  1_000_000_000...1_000_000_000_000 => :light_white
)

###############################################################################

class Integer
  def commatized_and_colorized(rjust=15)
    color = SIZE_COLORS[self] || :white
    s = commatize
    padding = " " * (rjust - s.size)

    "#{padding}<#{color}>#{s.gsub(",", "<8>,</8>")}".colorize
    #to_s.send(color)
  end

  def rjust(*args)
    to_s.rjust(*args)
  end

  def ljust(*args)
    to_s.ljust(*args)
  end
end

class NilClass
  def commatized_and_colorized(rjust=15)
    " " * 15
  end
end

###############################################################################

class Path

  def colorized(wide: false, regex: nil)
    fn   = regex ? filename.gsub(regex) { |match| "<14>#{match}</14>" } : filename
    line = ""

    if dir?
      line = dirs[-1].light_blue + "/"
    elsif symlink?
      line = "<11>#{fn}</11>"
      line += " <8>-> <#{target.exists? ? "7" : "12"}>#{target}" if wide
      line = line.colorize
    elsif color = FILENAME2COLOR[fn]
      line = "<#{color}>#{fn}</#{color}>"
    elsif executable?
      line = "<10>#{fn}</10>"
    else
      line = fn
    end

    line.colorize
  end

  def type
    if dir?
      :dir
    elsif type = FILENAME2TYPE[filename]
      type
    elsif ext.nil? or executable?
      :bin
    else
      nil
    end
  end

end

###############################################################################

def print_paths(paths, long: false, regex: nil, hidden: false)
  paths = paths.select { |path| path.filename =~ regex } if regex
  paths = paths.reject &:hidden? unless hidden

  if long
    paths.each do |path|
      fn = path.colorized(regex: regex, wide: true)
      time = (path.mtime.strftime("%Y-%m-%d") rescue "").ljust(10)
      size = path.size rescue nil
      puts "#{size.commatized_and_colorized} #{time} #{fn}"
    end
  else
    colorized_paths = paths.map { |path| path.colorized(regex: regex) }
    puts Term::Table.new(colorized_paths, :ansi=>true).by_columns
  end
end


###############################################################################
# Main
###############################################################################

#
# Snatch out the --<type> options before Slop sees them, so it doesn't blow up
#
types = TYPE_INFO.map &:first
selected_types = []
ARGV.each do |arg|
  if type = ARG2TYPE[arg.gsub(/^--/, '')]
    ARGV.delete(arg)
    selected_types << type
  end
end

#
# Parse normal arguments
#
opts = Slop.parse(help: true, strict: true) do
  banner "Usage: d [options] <file/dir(s)..>"

  on "v", "verbose",      'Enable verbose mode'
  on "l", "long",         'Long mode (with sizes and dates)'
  on "r", "recursive",    'Recursive'
  on "D", "dirs-first",   'Show directories first'
  on "a", "all"   ,       'Show all files (including hidden)'
  on "t", "time",         'Sort by modification time'
  on "T", "reverse-time", 'Sort by modification time (reversed)'
  on "s", "size",         'Sort by size'
  on "S", "reverse-size", 'Sort by size (reversed)'
  on "n", "dryrun",       'Dry-run', false
  on "g=","grep",         'Search filenames'
  on "f=","find",         'Find in directory tree'

  # on "f=", "type",    "File types to select (eg: #{types.join(', ')})"

  separator "        --<type name>       List files of this type (eg: #{types.join(', ')})"
end

# List the current directory if no files/dirs were specified
args = ARGV.empty? ? ["."] : ARGV

# Expand arguments into collections of files
grouped      = {}
single_files = []

args.each do |arg|
  path = Path[arg]

  unless path.exists?
    $stderr.puts "<12>Error: <15>#{root} <12>doesn't exist".colorize
    next
  end

  if path.dir?
    grouped[path] = opts.recursive? ? path.ls_R : path.ls
  else
    single_files << path
  end
end

grouped = grouped.update single_files.flatten.group_by(&:dir)
regex   = opts[:grep] ? Regexp.new(opts[:grep], Regexp::IGNORECASE) : nil

grouped.each do |dir, paths|
  if grouped.size > 1
    puts
    puts "<9>#{dir}".colorize
  end

  if selected_types.any?
    paths = paths.select { |path| selected_types.include? path.type }
  end

  if opts[:time] or opts["reverse-time"]
    paths.sort_by!(&:mtime)
  elsif opts[:size] or opts["reverse-size"]
    paths.sort_by!(&:size)
  else
    paths.sort_by!(&:path)
  end

  if opts.dirs_first?
    dirs, paths = paths.partition &:dir?
    print_paths(dirs, long: opts.long?, regex: regex, hidden: opts.a?)
  end

  print_paths(paths, long: opts.long?, regex: regex, hidden: opts.a?)
end
