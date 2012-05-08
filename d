#!/usr/bin/env ruby
require 'epitools'
gem 'slop', "2.4.4"; require 'slop'
#require 'find'

class DirLister
  COLORS = Rash.new(
    /(rb|c|c++|cpp|py|sh)$/i => :blue,
    /(mp3)$/i => :purple,
    /(mp4)$/i => :light_purple,
    /(jpe?g|bmp|png)$/i => :green,
    /(txt|pdf)$/i => :light_white,
    /(zip|rar|arj|pk3|deb|tar\.gz|tar\.bz2)$/i => :light_yellow
  )

  class ::Path
    def colorized(wide=true)
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

  SIZE_COLORS = Rash.new(
                 0..0 => :grey,
                1...1_000 => :yellow,
            1_000...1_000_000 => :cyan,
        1_000_000...1_000_000_000 => :light_blue,
    1_000_000_000...1_000_000_000_000 => :purple
  )

  class Integer
    def colorized
      color = SIZE_COLORS[self] || :white
      to_s.send(color)
    end

    def rjust(*args)
      to_s.rjust(*args)
    end

    def ljust(*args)
      to_s.ljust(*args)
    end
  end

  def show_long(path)
    fn = path.colorized(true)
    time = (path.mtime.strftime("%Y-%m-%d %H:%M:%S") rescue "").ljust(10)
    size = path.size rescue nil
    size = size.commatize.rjust(15).send(SIZE_COLORS[size] || :white) rescue ''
    puts "#{size} #{time} #{fn}"
  end

  def list_dir(dir, opts)
    root = ::Path[dir]
    paths = root.ls.sort

    if opts.long?
      paths.each do |path|
        show_long path
      end
    else
      files = paths.map{|path| path.colorized(false) }
      puts Term::Table.new(files, :ansi=>true).by_columns
    end
  end

  def self.list(*args)
    args.flatten!

    opts = Slop.new(args, :help => true) do
      banner "Usage: d"

      on :v, :verbose,  'Enable verbose mode'
      on :l, :long,     'Wide mode'
      on :n, :dryrun,   'Dry-run', false
    end

    ## Handle arguments

    args = []
    opts.parse { |arg| args << arg }

    args << "." if args.empty?

    lister = new
    args.each { |arg| lister.list_dir(arg, opts) }
  end
end


if $0 == __FILE__
  DirLister.list(*ARGV)
end

