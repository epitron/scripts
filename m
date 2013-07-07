#!/usr/bin/env ruby

# TODO:
#   - extract-keyframes
#   - extract-audio
#   - normalize audio
#   - mplayer-info
#   - commands (for operation-sensitive arguments)

#####################################################################################

require 'pp'

#####################################################################################

class FakeOptions
  def method_missing(*args); nil; end
end

#####################################################################################

def change_ext(path, new_ext)
  path.gsub(/\.[^\.]+$/, new_ext)
end  

#####################################################################################

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

#####################################################################################

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

#####################################################################################

def report_on(file)
  require 'epitools'

  Thread.new do |th|
    sleep 1
    puts
    loop do
      if File.exists? file
        print "\e[1G* Out file: #{File.size(file).commatize} bytes\e[J"
      end
      sleep 1
    end
  end
end

#####################################################################################

def extract_audio(file, outfile=nil, extras: [])
  
  outfile = change_ext(file, ".wav") unless outfile

  puts "* Extracting audio from: #{file}"
  puts "                     to: #{outfile}"

  report_thread = report_on(outfile)

  filtered_mplayer(
    %w[mplayer -vo null -af-clr -af resample=44100:0:1,format=s16ne] + ["-ao", "pcm:fast:file=%#{outfile.size}%#{outfile}", file] + extras,
    verbose: @opts[:verbose]
  )

  report_thread.kill

  outfile

end

#####################################################################################

def normalize(infile, outfile=nil)
  outfile = outfile || change_ext(infile, ".norm.wav")

  File.unlink outfile if File.exists? outfile

  cmd = %w[normalize --attack-exponent 1.1 -r 0.8 -o] + [outfile, infile]
  system(*cmd)
  outfile
end

def lame(infile, outfile=nil)
  outfile = outfile || change_ext(infile, ".mp3")
  cmd = %w[lame -V0] + [infile, outfile]
  system(*cmd)
  outfile
end

#####################################################################################
# OPTION PARSER

def parse_options
  require 'slop' # lazy loaded
  @opts = Slop.parse(help: true, strict: true) do
    banner 'Usage: m [options] <videos...>'

    on 'f',  'fullscreen',  'Fullscreen mode'
    on 'n',  'nosound',     'No sound'
    on 'c',  'crop',        'Auto-crop'
    on 'd',  'deinterlace', 'Deinterlace (using yadif)'
    on 'r=', 'aspect',      'Aspect ratio'
    on 's=', 'start',       'Start playing at this offset (HH:MM:SS or SS format)'
    on 'e=', 'end',         'Stop playing at this offset'
    on 'l=', 'length',      'Stop playing after this many seconds'
    on 'a=', 'audiofile',   'Play the audio track from a file'
    on 'w',  'wav',         'Dump audio to WAV file (same name as video, with .wav at the end)'
    on 'm',  'mp3',         'Dump audio to MP3 file (same name as video, with .mp3 at the end)'
    on 'o=', 'outfile',     'Output file (for MP3 and WAV commands)'
    on 'v',  'verbose',     'Show all mplayer output spam'
    on 'N',  'normalize',   'Normalize the audio in this video (saved to a magic filename that will be automatically played)'
  end
end

#####################################################################################

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
  extras = []

  cmd << "-nosound"         if opts.nosound?
  cmd << "-fs"              if opts.fullscreen?
  cmd += ["-vf", "yadif"]   if opts.deinterlace?
  cmd += ["-aspect", opts[:aspect]] if opts[:aspect]

  seek = opts[:start]

  if stop_at = opts[:end]
    require 'epitools'

    start_sec = (seek.from_hms || 0) 
    end_sec = stop_at.from_hms

    length = (end_sec - start_sec).to_hms
  else
    length = opts[:length]
  end

  extras += ["-ss", seek] if seek
  extras += ["-endpos", length] if length
  

  # AUDIOFILE / NORMED AUDIO
  audiofile = opts[:audiofile]
  unless audiofile
    normed_audio = change_ext(files.first, ".norm.mp3")
    audiofile = normed_audio if File.exists? normed_audio
  end
  cmd += ["-audiofile", audiofile] if audiofile


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

  if false
    # to make everything "elsifs" ;)

  elsif opts.normalize?

    files.each do |file|
      puts "=== Normalizing #{file} ==================="
      puts
      wav = extract_audio(file, extras: extras)

      puts
      puts "#"*70
      puts
      normwav = normalize(wav)
      #File.unlink wav

      puts
      puts "#"*70
      puts
      normmp3 = lame(normwav, change_ext(file, ".norm.mp3"))
      #File.unlink normwav

      puts
      puts
      puts "=== Normalization complete! ====================="
      puts
      puts "Result is stored in #{normmp3.inspect}, and will be played automatically."
      puts
    end

  elsif opts.mp3?

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
      extract_audio(file, opts[:outfile])
    end

  elsif opts.crop?

    files.each do |file|
      croptions = cropdetect(file)

      filtered_mplayer(
        cmd + extras + croptions + [file],
        verbose: opts.verbose?
      )      
    end

  else

    filtered_mplayer cmd + extras + files, verbose: opts.verbose?

  end

end

#####################################################################################