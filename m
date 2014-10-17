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

def run_with_stderr(*cmd)
  result = IO.popen(cmd, err: [:child, :out]) { |io| io.read }
  result.empty? ? nil : result
end

def change_ext(path, new_ext)
  path.gsub(/\.[^\.]+$/, new_ext)
end  

def getfattr(path)
  # # file: Scissor_Sisters_-_Invisible_Light.flv
  # user.m.options="-c"

  cmd = ["getfattr", "-d", "-e", "hex", path]

  attrs = {}

  IO.popen(cmd, "rb", :err=>[:child, :out]) do |io|
    io.each_line do |line|
      if line =~ /^([^=]+)=0x(.+)/
        key   = $1
        value = [$2].pack("H*") # unpack hex string

        attrs[key] = value
      end
    end
  end

  attrs
end

def setfattr(path, key, value)
  cmd = %w[setfattr]

  if value == nil
    # delete
    cmd += ["-x", key]
  else
    # set
    cmd += ["-n", key, "-v", value]
  end

  cmd << path

  IO.popen(cmd, "rb", :err=>[:child, :out]) do |io|
    result = io.each_line.to_a
    error = {cmd: cmd, result: result.to_s}.inspect
    raise error if result.any?
  end
end

def show_xattrs(path)
  attrs = getfattr(path)
  return if attrs.empty?

  valid_key   = /user\.(xdg|dublincore)/
  invalid_key = /description/
  grouped     = {}

  attrs.each do |key, val|
    next if not key[valid_key] or key[invalid_key]
    _, group, name = key.split(".", 3)
    grouped[group] ||= []
    grouped[group] << [name, val]
  end

  grouped.sort.each do |group, attrs|
    puts "[#{group}]"

    attrs.sort!
    attrs.each do |name, val|
      puts "  #{name} => #{val}"
    end
  end
end

def trap(*args, &block)
  options = if args.last.is_a?(Hash) then args.pop else Hash.new end
  args = [args].flatten
  signals = if args.any? then args else Signal.list.keys end

  ignore = %w[ VTALRM CHLD CLD EXIT ILL FPE BUS SEGV ] unless ignore = options[:ignore]
  ignore = [ignore] unless ignore.is_a? Array

  signals = signals - ignore

  signals.each do |signal|
    p [:sig, signal]
    Signal.trap(signal) { yield signal }
  end
end

#####################################################################################

def info(filename)

  output     = `mplayer -vo null -ao null -frames 0 -identify "#{filename}" 2>/dev/null|grep IDENTIFY`
  clip_info  = {}
  video_info = {}
  audio_info = {}
  info       = {}

  output.lines.each do |line|

    if line =~ /ID_([\dA-Z_]+)=(.+)$/
      name, val = $1, $2

      case name
      when /CLIP_INFO_(NAME|VALUE)(\d)+/
        clip_info[$2] ||= {}
        clip_info[$2][$1.downcase] = val
      when "EXIT", "DEMUXER", "CLIP_INFO_N", "FILENAME", "SEEKABLE"
        # skip it
      when /VIDEO_(.+)/
        video_info[$1.downcase] = val
      when /AUDIO_(.+)/
        audio_info[$1.downcase] = val
      else
        info[name.downcase] = val
      end

    end

  end

  keyvals = clip_info.map do |k, v|
    [v["name"], v["value"]]
  end

  clip_info_unsorted = Hash[ *keyvals.flatten ]

  clip_info_keys = [
   "title",
   "artist",
   "date",
   "creation_time",
   "album",
   "genre",
  ]

  clip_info = Hash[ *clip_info_keys.map { |key| [key, clip_info_unsorted.delete(key)] if clip_info_unsorted[key] }.compact.flatten ]
  clip_info.merge!(clip_info_unsorted)

  {
    "metadata" => clip_info,
    "video" => video_info,
    "audio" => audio_info,
    "info" => info,
  }

end

#####################################################################################

def cropdetect(file, verbose: false, seek: nil)
  captures = []

  cmd = %w[mplayer -quiet -ao null -frames 10 -vf cropdetect -vo null]
  cmd += ["-ss", seek || "60"]
  cmd += [file]

  p cmd if verbose

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

  # trap do
  #   # keep running in the background!
  #   system("notify-send", "my terminal disappeared! FUCK YOU TERMINAL!")
  # end

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

  # cmd.unshift("nohup")

  IO.popen(cmd, "rb", :err=>[:child, :out]) do |io|
    io.each_line(&filter)
  end
  
  puts
end

### BETA CODE #######################################################################

def filtered_mplayer_killable(cmd, verbose: false, &block)
  if verbose
    # Unfiltered!
    p cmd
    system(*cmd)
    return
  end

  # trap do
  #   # keep running in the background!
  #   system("notify-send", "my terminal disappeared! FUCK YOU TERMINAL!")
  # end


  # cmd.unshift("nohup")

  pid = fork do

    if block_given?
      filter = block
    else
      filter = proc do |line|
        p line
        case line
        when /^Playing (.+)\./
          STDOUT.puts
          STDOUT.puts $1
        when /DE(?:CVIDEO|MUX).+?(VIDEO: .+)/, /DECAUDIO.+?(AUDIO:.+)/
          STDOUT.puts " * #{$1}"
        when /DEC(VIDEO|AUDIO).+?Selected (.+)/
          STDOUT.puts "   |_ #{$2}"
        end
      end
    end

    Process.setsid # get immune to our parent's TTY signals
    Signal.trap("CLD") { exit } # mplayer died

    r, w = IO.pipe

    IO.popen(cmd, :err => [:child, :out]) do |io|
      begin
        Thread.new { IO.copy_stream(io, w) }
        r.each_line(&filter)
        # io.each_line(&filter)
        # loop do
        #   begin
        #     IO.copy_stream(io, STDOUT)
        #   rescue Errno::EIO # STDOUT is gone, but we still need to pump the input
        #   end
        # end
      rescue EOFError # mplayer died
        exit
      rescue Interrupt # parent wants us to go away
        exit # this kills mplayer with us with a SIGPIPE
      end
    end
  end
   
  loop do
    begin
      Process.wait(pid)
    rescue Interrupt
      Process.kill('INT', pid)
      # we still need to wait for mplayer to die
      # otherwise, the shell prints its prompt before mplayer has died
    rescue Errno::ECHILD
      exit
    end
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

  cmd =     %w[mplayer -vo null -af-clr -af resample=44100:0:1,format=s16ne] + 
      ["-ao", "pcm:fast:file=%#{outfile.size}%#{Shellwords.shellescape outfile}", file] + 
      extras

  filtered_mplayer cmd, verbose: @opts[:verbose]

  report_thread.kill

  outfile
end

#####################################################################################

def youtube_dl(url)
  # youtube-dl --get-url --get-filename -o '%(title)s.%(ext)s [%(extractor)s]' <url>
  # output: url \n title
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

  #@opts ||= Slop.new
  @opts = Slop.parse(help: true, strict: true) do
    banner 'Usage: m [options] <videos, or dirs...>'

    on 'f',  'fullscreen',  'Fullscreen mode'
    on 'n',  'nosound',     'No sound'
    on 'c',  'crop',        'Auto-crop'
    on 'i',  'info',        'Information about video (resolution, codecs)'
    on 'H',  'headers',     'Show all information in video file\'s headers'
    on 'd',  'deinterlace', 'Blend deinterlace (using yadif)'
    on 'p',  'pp',          'Postprocessing'
    on 'b',  'bob',         'Bob deinterlace (using yadif)'
    on 'r=', 'aspect',      'Aspect ratio'
    on 's=', 'start',       'Start playing at this offset (HH:MM:SS or SS format)'
    on 'e=', 'end',         'Stop playing at this offset'
    on 'l=', 'length',      'Stop playing after this many seconds'
    on 'a=', 'audiofile',   'Play the audio track from a file'
    on 'w',  'wav',         'Dump audio to WAV file (same name as video, with .wav at the end)'
    on 'm',  'mp3',         'Dump audio to MP3 file (same name as video, with .mp3 at the end)'
    on 'o=', 'outfile',     'Output file (for MP3 and WAV commands)'
    on 'M',  'mono',        'Fix the all-sound-coming-out-of-one-speaker problem'
    on 'N',  'normalize',   'Normalize the audio in this video (saved to a magic filename that will be automatically played)'
    on 'S',  'shuffle',     'Randomize the order of the videos'
    on 'i',  'index',       'Rebuild video\'s index (for seeking)'
    on 'v',  'verbose',     'Show all mplayer output spam'
  end
end

#####################################################################################

if $0 == __FILE__

  # PARSE OPTIONS
  # require 'pry'
  # binding.pry

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

  cmd   = %w[mplayer -quiet]
  extras = []

  cmd << "-nosound"                    if opts.nosound?
  cmd << "-fs"                         if opts.fullscreen?
  cmd << "-forceidx"                   if opts.index?
  cmd += ["-aspect", opts[:aspect]]    if opts[:aspect]
  cmd += ["-vf-add", "yadif"]          if opts.deinterlace?
  cmd += ["-vf-add", "yadif=1"]        if opts.bob?
  cmd += ["-vf-add", "scale=1280,pp7"] if opts.pp?

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

  extras += ["-af-add", "extrastereo=0,volume=5"] if opts.mono?

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

  cmd += %w[-vo null -ao null -endpos 0] if opts.info?

  # MAKE IT SO

  if false # ...so that everything is an "elsif"

  # elsif opts.info?

  #   cmd += %w[-vo null -ao null -endpos 0]
  #   filtered_mplayer cmd + files, verbose: opts.verbose?
    
  elsif opts.headers?

    require 'awesome_print'
    require 'epitools'

    lesspipe do |less|
      files.each do |file|
        less.puts "<8>### <14>#{file} <8>#{"#"*30}".colorize
        less.puts
        less.puts info(file).ai
        less.puts
      end
    end
    
  elsif opts.normalize?

    files.each do |file|
      puts "=== Normalizing #{file} ==================="
      puts
      wav = extract_audio(file, extras: extras)

      puts
      puts "#"*70
      puts
      normwav = normalize(wav)
      File.unlink wav

      puts
      puts "#"*70
      puts
      normmp3 = lame(normwav, change_ext(file, ".norm.mp3"))
      File.unlink normwav

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
      croptions = cropdetect(file, verbose: opts.verbose?, seek: opts[:start])

      filtered_mplayer(
        cmd + extras + croptions + [file],
        verbose: opts.verbose?
      )      
    end

  else
    videos = []
    cmd += %w[-cache 20000 -cache-min 0.0128] # 20 megs cache, start playing once 256k is cached

    # Populate the `videos` array
    files.each do |path|

      if File.directory? path
        # dirs
        if File.exists? File.join(path, "VIDEO_TS") or path[%r{(^|/)VIDEO_TS/?$}]
          # DVD
          videos << "dvd:///./#{path}"
        else
          # Directory full of videos
          require 'shellwords'
          videos += Dir[File.join(Shellwords.escape(path), "**/*.{avi,mkv,mp4,ogg,mov,mpg,mpeg}")]
        end
      else
        # Plain old file
        show_xattrs(path)
        videos << path
      end

    end

    videos = videos.sort_by { rand } if opts.shuffle?

    filtered_mplayer cmd + extras + videos, verbose: opts.verbose?
  end

end

#####################################################################################
