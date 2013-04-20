#!/usr/bin/env ruby
require 'pp'
require 'slop'

def cropdetect(file)
  captures = []

  cmd = %w[mplayer -ao null -ss 60 -frames 10 -vf cropdetect -vo null] + [file]

  IO.popen(cmd) do |io|
    io.each_line do |line|
      if line =~ /\((-vf) (crop=.+?)\)/
        captures << [$1, $2]
      end
    end
  end

  #["-vf", "crop=640:368:108:62"]
  grouped = captures.group_by { |c| c }.map{|k,v| [v.size, k] }.sort
  pp grouped
  best = grouped.last.last
end

def filtered_mplayer(cmd, verbose: false)
  # puts cmd.join(" ")
  if verbose
    system(*cmd)
    return
  end

  IO.popen(cmd, :err=>[:child, :out]) do |io|
    io.each_line do |line|
      case line
      when /^Playing (.+)\./
        puts
        puts $1
      when /DEMUX.+?(VIDEO: .+)/, /DECAUDIO.+?(AUDIO:.+)/
        puts " * #{$1}"
      when /DEC(VIDEO|AUDIO).+Selected (.+)/
        puts "   |_ #{$2}"
      end
    end
  end
  puts
end


def mplayer(files, flags=[], autocrop: false)
end


if $0 == __FILE__

  opts = Slop.parse(help: true, strict: true) do
    banner 'Usage: m [options] <videos...>'

    on 's=', 'seek', 'Seek to offset (HH:MM:SS or SS format)'
    on 'n', 'nosound', 'No sound'
    on 'c', 'crop', 'Auto-crop'
    on 'v', 'verbose', 'Show all mplayer output spam'
  end

  files = ARGV

  unless files.any?
    puts "Error: Must supply at least one video."
    puts
    puts opts
    exit 1
  end


  cmd   = ["mplayer"]
  cmd << "-nosound" if opts.nosound?

  if seek = opts[:seek]
    cmd += ["-ss", seek]
  end

  if files.size == 1
    title = files.first
  else
    title = "mplayer (#{files.size} files)"
  end

  cmd += ["-title", title]

  if opts.crop?
    files.each do |file|
      croptions = cropdetect(file)
      filtered_mplayer cmd + croptions + [file], verbose: opts.verbose?
    end
  else
    filtered_mplayer cmd + files, verbose: opts.verbose?
  end

end
