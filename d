#!/usr/bin/env ruby
###############################################################################
gem 'slop', "~> 3.6"
require 'slop'
require 'epitools/rash'
require 'epitools/path'
require 'epitools/colored'
require 'epitools/clitools'
###############################################################################

TYPE_INFO = [
  [:code,    /\.(rb|c|c++|cpp|py|sh|nim|pl|awk|go|php|ipynb)$/i,          :light_yellow],
  [:image,   /\.(jpe?g|bmp|png|o)$/i,                                     :green],
  [:video,   /\.(mp4|mkv|avi|m4v|flv|webm|mov|mpe?g|wmv)$/i,              :light_purple],
  [:music,   /\.(mp3|ogg|m4a|aac)$/i,                                     :purple],
  [:archive, /\.(zip|rar|arj|pk3|deb|tar\.(?:gz|xz|bz2)|tgz|pixz|gem)$/i, :light_yellow],
  [:doc,     /(Makefile|CMakeLists.txt|README|LICENSE|LEGAL|TODO|\.(txt|pdf|md|rdoc|log|mk))$/i, :light_white],
  [:config,  /\.(conf|ini)$/i,                                            :cyan],
  [:dotfile, /^\../i,                                                     :grey],
  [:data,    /\.(json|ya?ml|h)$/i,                                        :yellow],
  [:sidecar, /\.(srt|idx|sub|asc|sig|log|vtt)$/i,                         :grey],

]

FILENAME2COLOR = Rash.new TYPE_INFO.map { |name, regex, color| [regex, color] }
FILENAME2TYPE  = Rash.new TYPE_INFO.map { |name, regex, color| [regex, name] }

ARG2TYPE = Rash.new({
  /^(code|source|src)$/   => :code,
  /^(music|audio)$/       => :music,
  /^vid(eo)?s?$/          => :video,
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

def print_paths(paths, long: false, regex: nil, hidden: false, tail: false)
  paths  = paths.select { |path| path.filename =~ regex } if regex
  paths  = paths.reject &:hidden? unless hidden

  printer = proc do |output|
    if long
      paths.each do |path|
        fn = path.colorized(regex: regex, wide: true)
        time = (path.mtime.strftime("%Y-%m-%d") rescue "").ljust(10)
        size = path.size rescue nil
        output.puts "#{size.commatized_and_colorized} #{time} #{fn}"
      end
    else
      colorized_paths = paths.map { |path| path.colorized(regex: regex) }
      output.puts Term::Table.new(colorized_paths, :ansi=>true).by_columns
    end
  end

  if tail
    printer[$stdout]
  else
    lesspipe(&printer)
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
  on "H", "hidden",       'Show hidden files'
  on "t", "time",         'Sort by modification time'
  on "T", "reverse-time", 'Sort by modification time (reversed)'
  on "s", "size",         'Sort by size'
  on "S", "reverse-size", 'Sort by size (reversed)'
  on "p", "paged",        'Pipe output to "less"'
  on "n", "dryrun",       'Dry-run', false
  on "g=","grep",         'Search filenames'
  on "f=","find",         'Find in directory tree'

  separator "        --<type name>       List files of this type (possibilities: #{types.join(', ')})"

  # re_matchers = ARG2TYPE.keys.map { |re| re.to_s.scan(/\^(.+)\$/) }
  # separator "        --<type name>       List files of this type (will match: #{re_matchers.join(", ")})"
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

  start_pager_at_the_end = false
  if opts["time"]
    paths.sort_by!(&:mtime)
    start_pager_at_the_end = true
  elsif opts["reverse-time"]
    paths.sort_by!(&:mtime).reverse!
  elsif opts["size"]
    paths.sort_by!(&:size)
    start_pager_at_the_end = true
  elsif opts["reverse-size"]
    paths.sort_by!(&:size).reverse!
  else
    paths.sort_by! { |path| path.path.downcase }
  end

  if opts.dirs_first?
    dirs, paths = paths.partition(&:dir?)
    paths = dirs + paths
  end

  print_paths(paths, long: opts.long?, regex: regex, hidden: opts.hidden?, tail: start_pager_at_the_end)
end
