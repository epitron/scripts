#!/usr/bin/env ruby
########################################################
require 'epitools'

gem 'slop', "~> 3.6"
require 'slop'
########################################################



########################################################
# Parse options

opts = Slop.parse(help: true, strict: true) do
  banner "Usage: tag [options] <media file(s)...>"

  on "n",  "dryrun",  "do nothing"
  on "v",  "verbose", "show debug information"
  on "a=", "artist",  "set the artist name manually"
  on "A=", "album",   "set the album name manually"
  on "d=", "date",    "set the date manually"
  on "t=", "title",   "set the title manually"
end

########################################################

paths = ARGV.map &:to_Path
tmp = Path.tmpdir

if opts.title? and paths.size > 1
  $stderr.puts "Error: You can only manually override the title for a single file at a time"
  exit 1
end

paths.each do |inp|
  out = tmp/"tagged.#{inp.ext}"

  artist, title = inp.basename.split(/\b {1,3}- {1,3}\b/, 2)
  if artist =~ /^(\d{1,2})(?:\.| -) (.+)/ # starts with "00. " or "00 - "
    track = $1.to_i
    artist = $2
  end
  title, artist = artist, title if title.nil?

  if title =~ /^(\d{1,2})(?: -|\.) (.+?)$/ # redundant (but necessary...?)
    track = $1.to_i
    title = $2
  end

  # refrence: http://jonhall.info/create_id3_tags_using_ffmpeg/
  tags = {}

  tags[:artist] = artist
  tags[:title]  = title
  tags[:track]  = track if track

  tags[:title]  = opts[:title]  if opts.title?
  tags[:artist] = opts[:artist] if opts.artist?
  tags[:date]   = opts[:date]   if opts.date?
  tags[:album]  = opts[:album]  if opts.album?

  cmd = ["ffmpeg", "-hide_banner", "-v", "error", "-i", inp, "-c", "copy"]
  cmd += tags.flat_map { |k,v| ["-metadata", "#{k}=#{v}"] }
  cmd << out

  puts "* #{inp.filename}"
  tags.each { |k,v| puts "  |_ #{k}: #{v}" }
  system *cmd
  puts "  |_ outsize: #{out.size.commatize}"
  puts

  if out.size < 1024 # or (out.size - inp.size) > -128000
    out.rm
    raise "Error: resulting file is too small."
  else
    out.mv inp
  end

end

tmp.rm
