#!/usr/bin/env ruby
########################################################
require 'json'
require 'coderay'
require 'pp'
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

  puts "Request:"
  pr opts
  puts

  output = curl("-s", "-X", "POST", "--header", "Content-Type: application/json", "-d", JSON.dump(opts), kodi_rpc_url)

  if output.empty?
    raise "Error: output is blank"
    # exit 1
  end

  json = JSON.parse(output)

  if error = json["error"]
    puts "RPC Error:"
    ph error
    # exit 2
    raise
  end

  json["result"]
end

########################################################

def ph(hash)
  puts CodeRay.scan(JSON.pretty_generate(hash), :json).term
end

def pr(obj)
  puts CodeRay.scan(obj.inspect, :ruby).term
end

def help!
  puts DATA.read
  exit
end

########################################################

# https://github.com/pla1/utils/blob/master/kodiJsonExamples.sh

def to_kodipath(url)
  case url
  when %r{https?://(?:www\.)?youtube\.com/(?:embed|watch)\?v=([^&]+)}, %r{https?://youtu\.be/(.+)}
    "plugin://plugin.video.youtube/?action=play_video&videoid=#{$1}"
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
  ph rpc(
    method: "Playlist.GetPlaylists",
  )
end

def playlist(id=1)
  ph rpc(
    method: "Playlist.Getitems",
    params: {playlistid: id, properties: %w[title duration file]},
  )
end

def playlist_add(url)
  result = rpc(
    method: "Playlist.Add",
    params: {
      playlistid: 1,
      item: {
        file: to_kodipath(url),
        # label: "A video",
        # title: "",
      }
    },
  )
  ph result

  player_playpause unless active_player_id
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
  result = rpc(method: "Player.GetActivePlayers")
  result&.first&.[]("playerid")
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

def player_playpause
  if id = active_player_id
    ph rpc(
      method: "Player.PlayPause",
      params: {
        playerid: id
      }
    )
  else
    ph rpc(
      method: "Player.Open",
      params: { item: { playlistid: 1 } },
    )
  end
end

def player_stop
  if id = active_player_id
    ph rpc(
      method: "Player.Stop",
      params: {
        playerid: id,
      }
    )
  end
end

def player_seek(time_string)
  time_hash = %i[seconds minutes hours].zip(time_string.split(":").reverse).to_h
  rpc(method: "Player.Seek", params: {playerid: 1, value: time_hash})
end

########################################################

opts, args = ARGV.partition { |arg| arg[/^--?\w+/] }

if opts.delete("-i")
  ph jsonrpc_introspect
elsif opts.include?("-I")
  CodeRay::Encoders::Terminal::TOKEN_COLORS[:comment] = {} # ugly hack
  require 'pry'
  binding.pry
  exit
elsif opts.delete("-L")
  playlists
elsif opts.delete("-l")
  playlist
elsif opts.delete("-n")
  playlist_next
elsif opts.delete("-b")
  playlist_prev
elsif opts.delete("-c")
  playlist_clear
  player_stop
elsif opts.delete("-p")
  player_playpause
elsif opts.delete("-s")
  player_stop
else
  if args.empty?
    help!
  else
    args.each do |arg|
      puts "Adding: #{arg}"
      playlist_add(arg)
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
  -n  Play next item
  -b  Play previous item
  -c  Clear playlist
  -L  Show playlists
  -I  Interactive repl
  -i  Full RPC function list