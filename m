#!/usr/bin/env ruby

# TODO:
#   - extract-keyframes
#   - extract-audio
#   - normalize audio
#   - mplayer-info

require 'pp'

class FakeOptions
  def method_missing(*args); nil; end
end


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

def filtered_mplayer(cmd, verbose: false, &block)
  if verbose
    # Unfiltered!
    p cmd
    system(*cmd)
    return
  end

  if block_given?
    filter = block
  else
    filter = proc do |line|
      case line
      when /^Playing (.+)\./
        puts
        puts $1
      when /DE(?:CVIDEO|MUX).+?(VIDEO: .+)/, /DECAUDIO.+?(AUDIO:.+)/
        puts " * #{$1}"
      when /DEC(VIDEO|AUDIO).+?Selected (.+)/
        puts "   |_ #{$2}"
      end
    end
  end

  IO.popen(cmd, :err=>[:child, :out]) do |io|
    io.each_line(&filter)
  end
  puts
end

def change_ext(path, new_ext)
  path.gsub(/\.[^\.]+$/, new_ext)
end  

def parse_options
  require 'slop'
  opts = Slop.parse(help: true, strict: true) do
    banner 'Usage: m [options] <videos...>'

    on 's=', 'seek', 'Seek to offset (HH:MM:SS or SS format)'
    on 'f', 'fullscreen', 'Fullscreen mode'
    on 'n', 'nosound', 'No sound'
    on 'c', 'crop', 'Auto-crop'
    on 'a=', 'audiofile', 'Play the audio track from a file'
    on 'w', 'wav', 'Dump audio to WAV file (same name as video, with .wav at the end)'
    on 'm', 'mp3', 'Dump audio to MP3 file (same name as video, with .mp3 at the end)'
    on 'o', 'output', 'Output file (for MP3 and WAV commands)'
    on 'v', 'verbose', 'Show all mplayer output spam'
  end
end


if $0 == __FILE__

  # PARSE OPTIONS

  if ARGV.empty? or ARGV.any? { |opt| opt[/^-/] }
    opts = parse_options
  else
    opts = FakeOptions.new
  end

  files = ARGV

  unless files.any?
    puts "Error: Must supply at least one video file."
    puts
    puts parse_options
    exit 1
  end

  # MPLAYER ARGS

  cmd   = %w[mplayer]
  cmd << "-nosound" if opts.nosound?
  cmd << "-fs"      if opts.fullscreen?

  if seek = opts[:seek]
    cmd += ["-ss", seek]
  end

  if audiofile = opts[:audiofile]
    cmd += ["-audiofile", audiofile]
  end

  # TITLE

  if files.size == 1
    title = File.basename files.first
  else
    title = "mplayer (#{files.size} files)"
  end

  cmd += ["-title", title]

  # ENSURE ONLY ONE COMMAND

  class Array
    def one_or_none?(&block)
      one?(&block) or none?(&block)
    end
  end

  mutually_exclusive_args = %w[crop mp3 wav]
  unless mutually_exclusive_args.one_or_none? { |option| opts.send(option + "?") }
    puts "Error: Can only specify one of these options:"
    puts "   #{mutually_exclusive_args.map{|x| "--" + x }.join(", ")}"
  end

  # MAKE IT SO

  if opts.mp3?

    files.each do |file|
      outfile = opts[:outfile] || change_ext(file, ".mp3")

      puts "* Extracting audio from: #{file}"
      puts "                     to: #{outfile}"

      filtered_mplayer(
        %w[mencoder -of rawaudio -oac mp3lame -ovc copy -o] + [outfile, file], 
        verbose: true
      ) do |line|
        if line =~ /^Pos:.+\((\d+%)\)/
          print "\b"*6 + $1
        end
      end
    end

  elsif opts.wav?

    files.each do |file|
      outfile = opts[:outfile] || change_ext(file, ".wav")

      puts "* Extracting audio from: #{file}"
      puts "                     to: #{outfile}"

      filtered_mplayer(
        %w[mplayer -vo null -ao] + ["pcm:fast:file=%#{outfile.size}%#{outfile}", file],
        verbose: false
      )
    end

  elsif opts.crop?

    files.each do |file|
      croptions = cropdetect(file)

      filtered_mplayer(
        cmd + croptions + [file],
        verbose: opts.verbose?
      )      
    end

  else

    filtered_mplayer cmd + files, verbose: opts.verbose?

  end

end
