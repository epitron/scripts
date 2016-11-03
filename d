#!/usr/bin/env ruby
###############################################################################
gem 'slop', "~> 3.6"
require 'slop'
require 'epitools'
###############################################################################

COLORS = Rash.new(
  /(rb|c|c++|cpp|py|sh)$/i                   => :blue,
  /(mp3)$/i                                  => :purple,
  /(mp4|mkv|avi|m4v)$/i                      => :light_purple,
  /(srt|idx|sub)$/i                          => :grey,
  /(jpe?g|bmp|png)$/i                        => :green,
  /(txt|pdf)$/i                              => :light_white,
  /(zip|rar|arj|pk3|deb|tar\.gz|tar\.bz2)$/i => :light_yellow
)


class Path
  def colorized(wide: true)
    fn = ""
    if dir?
      fn = dirs[-1].light_blue + "/"
    elsif symlink?
      fn = "<11>#{filename}"
      fn += " <8>-> <7>#{symlink_target}" if wide
      fn = fn.colorize
    elsif color = COLORS[filename]
      fn = filename.send(color)
    elsif exe?
      fn = filename.light_green
    else
      fn = filename
    end
    fn
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
  def colorized(rjust=15)
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

###############################################################################

class DirLister

  def show_long(path)
    fn = path.colorized(true)
    time = (path.mtime.strftime("%Y-%m-%d %H:%M:%S") rescue "").ljust(10)
    size = path.size rescue nil
    #size = size.commatize.rjust(15).send(SIZE_COLORS[size] || :white) rescue ''
    size = size.colorized
    puts "#{size} #{time} #{fn}"
  end

  def list_dir(dir, opts)
    root = Path[dir]

    paths = root.ls

    if opts[:time] or opts["reverse-time"]
      paths.sort_by!(&:mtime)
    elsif opts[:size] or opts["reverse-size"]
      paths.sort_by!(&:size)
    else
      paths.sort_by!(&:path)
    end

    paths.reverse! if opts["reverse-size"] or opts["reverse-time"]

    dirs, files = paths.partition(&:dir?)
    paths       = dirs + files

    if opts.long?
      (dirs+files).each do |path|
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

opts = Slop.parse(help: true, strict: true) do
  banner "Usage: d"

  on :v, :verbose,  'Enable verbose mode'
  on :l, :long,     'Wide mode'
  on :r, :recursive,'Recursive'
  on :t, :time,     'Sort by modification time'
  on :T, "reverse-time", 'Sort by modification time (reversed)'
  on :s, :size,     'Sort by size'
  on :S, "reverse-size", 'Sort by size (reversed)'
  on :n, :dryrun,   'Dry-run', false
end

args = []
opts.parse { |arg| args << arg }

args << "." if args.empty?

lister = DirLister.new
args.each { |arg| lister.list_dir(arg, opts) }
