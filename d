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
  [:archive, /\.(zip|rar|arj|pk3|deb|tar\.gz|tar\.bz2)$/i, :light_yellow]
]

FILENAME2COLOR = Rash.new TYPE_INFO.map { |name, regex, color| [regex, color] }
FILENAME2TYPE  = Rash.new TYPE_INFO.map { |name, regex, color| [regex, name] }

ARG2TYPE = Rash.new({
  /^(code|source|src)$/   => :code,
  /^music$/               => :music,
  /^videos?$/             => :video,
  /^(subs?)$/             => :sub,
  /^(image?s|pics?|pix)$/ => :image,
  /^(text|docs?)$/        => :doc,
  /^(archives?|zip)$/     => :archive,
  /^(dir|directory)$/     => :dir,
})

###############################################################################

class Path
  def colorized(wide: true)
    fn = ""
    if dir?
      fn = dirs[-1].light_blue + "/"
    elsif symlink?
      fn = "<11>#{filename}"
      fn += " <8>-> <#{target.exists? ? "7" : "12"}>#{target}" if wide
      fn = fn.colorize
    elsif color = FILENAME2COLOR[filename]
      fn = filename.send(color)
    elsif exe?
      fn = filename.light_green
    else
      fn = filename
    end
    fn
  end

  def type
    dir? ? :dir : FILENAME2TYPE[filename]
  end

end

###############################################################################

SIZE_COLORS = Rash.new(
              0...100 => :grey,
            100...1_000 => :blue,
          1_000...1_000_000 => :light_blue,
      1_000_000...1_000_000_000 => :light_cyan,
  1_000_000_000...1_000_000_000_000 => :light_white
)


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

class DirLister

  def show_long(path)
    fn = path.colorized
    # time = (path.mtime.strftime("%Y-%m-%d %H:%M:%S") rescue "").ljust(10)
    time = (path.mtime.strftime("%Y-%m-%d") rescue "").ljust(10)
    #   size = -1
    # else
    size = path.size rescue nil
    # end
    #size = size.commatize.rjust(15).send(SIZE_COLORS[size] || :white) rescue ''
    puts "#{size.commatized_and_colorized} #{time} #{fn}"
  end

  def list_dir(root, opts, selected_types=[])

    unless root.exists? and root.dir?
      $stderr.puts "<12>Error: <15>#{root} <12>doesn't exist".colorize
      return
    end

    paths = root.ls

    if selected_types.any?
      paths = paths.select { |path| selected_types.include? path.type  }
    end

    if opts[:time] or opts["reverse-time"]
      paths.sort_by!(&:mtime)
    elsif opts[:size] or opts["reverse-size"]
      paths.sort_by!(&:size)
    else
      paths.sort_by!(&:path)
    end

    paths.reverse! if opts["reverse-size"] or opts["reverse-time"]

    dirs, files = paths.partition(&:dir?)
    paths = dirs + files # dirs first!

    if opts.long?
      paths.each do |path|
        show_long path
      end
    else
      puts Term::Table.new(dirs.map  { |path| path.colorized(wide: false) }, :ansi=>true).by_columns
      puts Term::Table.new(files.map { |path| path.colorized(wide: false) }, :ansi=>true).by_columns
    end
  end

end

###############################################################################

# args.flatten!

types = TYPE_INFO.map &:first
selected_types = []
ARGV.each do |arg|
  if type = ARG2TYPE[arg.gsub(/^--/, '')]
    ARGV.delete(arg)
    selected_types << type
  end
end

opts = Slop.parse(help: true, strict: true) do
  banner "Usage: d"

  on "v", "verbose",  'Enable verbose mode'
  on "l", "long",     'Long mode (with sizes and dates)'
  on "r", "recursive",'Recursive'
  on "t", "time",     'Sort by modification time'
  on "T", "reverse-time", 'Sort by modification time (reversed)'
  on "s", "size",     'Sort by size'
  on "S", "reverse-size", 'Sort by size (reversed)'
  on "n", "dryrun",   'Dry-run', false
  # on "f=", "type",    "File types to select (eg: #{types.join(', ')})"

  separator "        --<type name>       List files of this type (eg: #{types.join(', ')})"
end

args = []
opts.parse { |arg| args << arg }

args << "." if args.empty?

lister = DirLister.new
paths = args.map { |arg| Path[arg] }

paths.each { |path| lister.list_dir(path, opts, selected_types) }
