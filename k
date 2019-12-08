#!/usr/bin/env ruby
########################################################
require 'json'
require 'coderay'
require 'pp'
require 'pathname'
########################################################

KODIRC = File.expand_path("~/.kodirc")
CONFIG = %i[host port user pass].zip(File.read(KODIRC).each_line.map(&:strip)).to_h

THEMES = {
  siberia:   {:class=>"\e[34;1m", :class_variable=>"\e[34;1m", :comment=>"\e[33m", :constant=>"\e[34;1m", :error=>"\e[37;44m", :float=>"\e[33;1m", :global_variable=>"\e[33;1m", :inline_delimiter=>"\e[32m", :instance_variable=>"\e[34;1m", :integer=>"\e[33;1m", :keyword=>"\e[36m", :method=>"\e[36;1m", :predefined_constant=>"\e[36;1m", :symbol=>"\e[36m", :regexp=>{:modifier=>"\e[36m", :self=>"\e[34;1m", :char=>"\e[36;1m", :content=>"\e[34;1m", :delimiter=>"\e[34m", :escape=>"\e[36m"}, :shell=>{:self=>"\e[34;1m", :char=>"\e[36;1m", :content=>"\e[34;1m", :delimiter=>"\e[36m", :escape=>"\e[36m"}, :string=>{:self=>"\e[34;1m", :char=>"\e[36;1m", :content=>"\e[34;1m", :delimiter=>"\e[36m", :escape=>"\e[36m"}},
  ocean:     {:class=>"\e[38;5;11m", :class_variable=>"\e[38;5;131m", :comment=>"\e[38;5;8m", :constant=>"\e[38;5;11m", :error=>"\e[38;5;0;48;5;131m", :float=>"\e[38;5;173m", :global_variable=>"\e[38;5;131m", :inline_delimiter=>"\e[38;5;137m", :instance_variable=>"\e[38;5;131m", :integer=>"\e[38;5;173m", :keyword=>"\e[38;5;139m", :method=>"\e[38;5;4m", :predefined_constant=>"\e[38;5;131m", :symbol=>"\e[38;5;10m", :regexp=>{:modifier=>"\e[38;5;10m", :self=>"\e[38;5;10m", :char=>"\e[38;5;152m", :content=>"\e[38;5;152m", :delimiter=>"\e[38;5;10m", :escape=>"\e[38;5;137m"}, :shell=>{:self=>"\e[38;5;10m", :char=>"\e[38;5;152m", :content=>"\e[38;5;10m", :delimiter=>"\e[38;5;10m", :escape=>"\e[38;5;137m"}, :string=>{:self=>"\e[38;5;10m", :char=>"\e[38;5;152m", :content=>"\e[38;5;10m", :delimiter=>"\e[38;5;10m", :escape=>"\e[38;5;137m"}},
  modern:    {:class=>"\e[38;5;207;1m", :class_variable=>"\e[38;5;80m", :comment=>"\e[38;5;24m", :constant=>"\e[38;5;32;1;4m", :error=>"\e[38;5;31m", :float=>"\e[38;5;204;1m", :global_variable=>"\e[38;5;220m", :inline_delimiter=>"\e[38;5;41;1m", :instance_variable=>"\e[38;5;80m", :integer=>"\e[38;5;37;1m", :keyword=>"\e[38;5;167;1m", :method=>"\e[38;5;70;1m", :predefined_constant=>"\e[38;5;14;1m", :symbol=>"\e[38;5;83;1m", :regexp=>{:modifier=>"\e[38;5;204;1m", :self=>"\e[38;5;208m", :char=>"\e[38;5;208m", :content=>"\e[38;5;213m", :delimiter=>"\e[38;5;208;1m", :escape=>"\e[38;5;41;1m"}, :shell=>{:self=>"\e[38;5;70m", :char=>"\e[38;5;70m", :content=>"\e[38;5;70m", :delimiter=>"\e[38;5;15m", :escape=>"\e[38;5;41;1m"}, :string=>{:self=>"\e[38;5;41m", :char=>"\e[38;5;41m", :content=>"\e[38;5;41m", :delimiter=>"\e[38;5;41;1m", :escape=>"\e[38;5;41;1m"}},
  solarized: {:class=>"\e[38;5;136m", :class_variable=>"\e[38;5;33m", :comment=>"\e[38;5;240m", :constant=>"\e[38;5;136m", :error=>"\e[38;5;254m", :float=>"\e[38;5;37m", :global_variable=>"\e[38;5;33m", :inline_delimiter=>"\e[38;5;160m", :instance_variable=>"\e[38;5;33m", :integer=>"\e[38;5;37m", :keyword=>"\e[38;5;246;1m", :method=>"\e[38;5;33m", :predefined_constant=>"\e[38;5;33m", :symbol=>"\e[38;5;37m", :regexp=>{:modifier=>"\e[38;5;160m", :self=>"\e[38;5;64m", :char=>"\e[38;5;160m", :content=>"\e[38;5;64m", :delimiter=>"\e[38;5;160m", :escape=>"\e[38;5;160m"}, :shell=>{:self=>"\e[38;5;160m", :char=>"\e[38;5;160m", :content=>"\e[38;5;37m", :delimiter=>"\e[38;5;160m", :escape=>"\e[38;5;160m"}, :string=>{:self=>"\e[38;5;160m", :char=>"\e[38;5;160m", :content=>"\e[38;5;37m", :delimiter=>"\e[38;5;160m", :escape=>"\e[38;5;37m"}},
}

CodeRay::Encoders::Terminal::TOKEN_COLORS.merge!(THEMES[:modern])

########################################################

# class Kodi
#   def players
#   end

#   class Player
#     play
#     pause
#     stop
#     playlist
#     class Playlist
#       show
#       add
#       clear
#     end
#   end
# end



class Pathname
  def abspath; realpath; end
end

def parse_player_id(args)
  args.any? { |arg| arg[/^(\d+)$/] } ? $1.to_i : nil
end

def args_to_urls(*args)
  args = args.flatten

  args.map do |arg|
    next if arg[/\.mov$/]

    if arg =~ %r{^https?://.+}
      if arg =~ %r{^http://127.0.0.1:\d+/([^\.]+).mpd}
        arg = "https://youtu.be/#{$1}"
      end

      arg
    else
      # TODO: if ~/g, grog:8887, if ~/laptop, laptop:8887
      paths = Pathname.glob(arg)
      paths.
        map { |path| path.abspath.relative_path_from("/home/pip/g/") rescue nil }.
        compact.
        map { |path| "http://grog:8887/#{URI.escape path.to_s}" }
      # raise "error: couldn't parse #{arg.inspect}"
    end
  end.flatten.compact
end

# p args_to_urls("*.mp4")
# exit

def kodi_rpc_url
  "http://#{CONFIG[:user]}:#{CONFIG[:pass]}@#{CONFIG[:host]}:#{CONFIG[:port]}/jsonrpc"
end

def curl(*args)
  cmd = ["curl", *args]
  # pr cmd
  IO.popen(cmd, &:read)
end

def rpc(opts)
  opts[:jsonrpc] ||= "2.0"
  opts[:id] ||= 1

  pr opts

  output = curl("-s", "-X", "POST", "--header", "Content-Type: application/json", "-d", JSON.dump(opts), kodi_rpc_url)

  if output.empty?
    raise "Error: output is blank"
    # exit 1
  end

  json = JSON.parse(output)

  if error = json["error"]
    ph error.to_a
    # ph error
    # exit 2
    raise error.to_s
  end

  json["result"]
end

########################################################

def ph(hash)
  puts CodeRay.scan(JSON.pretty_generate(hash), :json).term if $verbose
end

def pr(obj)
  puts CodeRay.scan(obj.inspect, :ruby).term if $verbose
end

def help!
  puts DATA.read
end

########################################################

# https://github.com/pla1/utils/blob/master/kodiJsonExamples.sh

def to_kodipath(url)
  case url
  when %r{https?://(?:www\.)?youtube\.com/(?:embed|watch)\?v=([^&]+)}, %r{https?://youtu\.be/(.+)}
    "plugin://plugin.video.youtube/play/?video_id=#{$1}"
  when %r{https?://(?:www\.)?thoughtmaybe\.com/}
    IO.popen(["youtube-dl", "-g", url], &:read).chomp
  else
    url
  end
end

def jsonrpc_introspect
  rpc(method: "JSONRPC.Introspect")
end

def players
  rpc(method: "Player.GetPlayers")
end

def playlists
  rpc(
    method: "Playlist.GetPlaylists",
  )
end

def playlist(id=1)
  rpc(
    method: "Playlist.Getitems",
    params: {playlistid: id, properties: %w[title duration file]},
  )
end

def playlist_size(id=1)
  playlist(id)["items"].size
end

def playlist_add(url, id=1)
  item = {file: to_kodipath(url)}

  result = rpc(
    method: "Playlist.Add",
    params: {
      playlistid: id,
      item: item,
    },
  )

  ph result
end

# def playlist_add(*args)

#   args.each do |arg|
#     next if arg[/\.mov$/]

#     (arg)
#     when URI
#       url = thing.to_s

#       # rewrite bad args
#       if url =~ %r{^http://127.0.0.1:\d+/([^\.]+).mpd}
#         url = "https://youtu.be/#{$1}"
#       end

#       p url
#       url
#     when Pathname
#       p file: thing
#     else
#       raise "unknown thing: #{thing.inspect}"
#     end

#     next

#     item = {file: to_kodipath(arg)}

#     result = rpc(
#       method: "Playlist.Add",
#       params: {
#         playlistid: 1,
#         item: item,
#       },
#     )

#     ph result
#   end

# end

def shuffle_current_playlist
  shuffled = playlist["items"].map { |item| item["file"] }.shuffle
  playlist_clear
  playlist_add(*shuffled)
end

def playlist_clear(id=1)
  ph rpc(
    method: "Playlist.Clear",
    params: {
      playlistid: 1
    },
  )
end

def active_player_id
  @result ||= rpc(method: "Player.GetActivePlayers")
  @result&.first&.[]("playerid")
end

def playlist_jump(pos)
  ph rpc(
    method: "Player.GoTo",
    params: {playerid: 1, to: pos},
  )
end

def playlist_next
  playlist_jump("next")
end

def playlist_prev
  playlist_jump("previous")
end

def player_play(id=1)
  ph rpc(
    method: "Player.Open",
    params: { item: { playlistid: id } },
  )
end

def player_playpause(id=nil)
  if id = (id || active_player_id)
    ph rpc(
      method: "Player.PlayPause",
      params: {
        playerid: id
      }
    )
  else
    player_play(1)
  end
end

def player_stop(id=nil)
  if id = (id || active_player_id)
    ph rpc(
      method: "Player.Stop",
      params: {
        playerid: id,
      }
    )
  end
end

def player_seek(time_string)
  time_hash = %i[seconds minutes hours].zip(time_string.split(":").reverse.map(&:to_i)).to_h
  time_hash[:hours] ||= 0
  time_hash[:milliseconds] = 0
  rpc(method: "Player.Seek", params: {playerid: 1, value: time_hash})
end

def set_volume(value)
  rpc(method: "Application.SetVolume", params: {volume: value})
end

def clear
  print "\e[H\e[J"
end

def pretty_print_playlist
  # TODO: crop playlist to a region around the current track (centred in cropped window, or positioned in chunky cropped window (crop mod page-size)) 
  items = playlist.to_h["items"]

  # clear

  items.each_with_index do |item, i|
    label, title, file = item.values_at(*%w[label title file])

    desc = nil
    desc ||= title unless title.empty?
    desc ||= label unless label.empty?
    desc ||= file unless file.empty?

    puts "#{i+1}. #{desc}"
  end
end

########################################################

opts, args = ARGV.partition { |arg| arg[/^--?\w+/] }

$verbose = opts.include?("-v")

if (opts.empty? and args.empty?) or (opts.include?("-h") or opts.include?("--help"))
  help!
  exit
end

# clear playlist
if opts.include?("-c")
  playlist_clear
  player_stop
end

# print the api specs as a giant json blob
if opts.include?("-i")
  ph jsonrpc_introspect

# pry
elsif opts.include?("-I")
  puts "Usage:"
  puts "  > rpc(method: 'Some.Method', params: {value: 'woot'})"
  puts "  > jsonrpc_introspect"
  puts
  CodeRay::Encoders::Terminal::TOKEN_COLORS[:comment] = {} # ugly hack
  require 'pry'
  binding.pry
  exit

# # prettyprinted playlist
# elsif opts.include?("-ppp")
#   pretty_print_playlist

# ?
elsif opts.include?("-L")
  ph playlists

# list
elsif opts.include?("-l")
  list = ( id = parse_player_id(args) ) ? playlist(id) : playlist
  $verbose ? ph(list) : pretty_print_playlist

# next
elsif opts.include?("-n")
  playlist_next

# prev
elsif opts.include?("-b")
  playlist_prev

# play/pause
elsif opts.include?("-p")
  player_playpause

# enqueue what's in audacious
elsif opts.include?("-a")
  playlist_add(`audtool current-song-filename`.strip)

# stop
elsif opts.include?("-s")
  player_stop

# shuffle
elsif opts.include?("-S")
  shuffle_current_playlist

# volume
elsif opts.include?("-V")
  if volume = args.find { |arg| arg[/^\d+/] }
    set_volume(volume.to_i)
  end

# seek
elsif opts.include?("-t")
  if time = args.find { |arg| arg =~ /\d?\d(:\d\d){1,2}/ }
    player_seek(time)
  end

else

  if args.empty? and opts.empty?

    help!

  else

    to_play = playlist_size

    # enqueue
    args_to_urls(*args).each do |url|
      playlist_add(url)
      puts "Added: #{url}"
    end

    unless id = active_player_id
      # play(to_play)
      player_playpause
    end


  end
end

__END__
purpose:
  Play things in Kodi

usage:
  k [options] <url(s)>

configuration:
  Make a ~/.kodirc file with the kodi RPC server's hostname, port, username,
  and password on their own lines.

options:
  -l  List playlist
  -p  Play/Pause
  -s  Stop
  -S  Shuffle current playlist
  -n  Play next item
  -b  Play previous item
  -v  verbose
  -V <volume>
      Set the volume (0-100)
  -t <timestamp>
      Seek to timestamp (eg: "5:21")
  -c  Clear playlist
  -a  Add whatever's playing in Audacious to the playlist
  -L  Show playlists
  -I  Interactive repl
  -i  Full RPC function list
