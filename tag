#!/usr/bin/env ruby
########################################################
require 'epitools'

gem 'slop', "~> 3.6"
require 'slop'
########################################################



########################################################
# Parse options

opts = Slop.parse(help: true, strict: true) do
  banner "Usage: tag [options]"

  on "n", "dryrun",  "do nothing"
  # on "b=", "blong",  "desc", default: ""
end

########################################################

paths = ARGV.map &:to_Path
tmp = Path.tmpdir

paths.each do |inp|
  out = tmp/"tagged.#{inp.ext}"

  artist, title = inp.basename.split(/\b {1,3}- {1,3}\b/, 2)
  if artist =~ /^(\d{1,2})(?:\.| -) (.+)/ # starts with "00. " or "00 - "
    track = $1.to_i
    artist = $2
  end
  title, artist = artist, title if title.nil?

  # refrence: http://jonhall.info/create_id3_tags_using_ffmpeg/
  tags = {}

  tags[:artist] = artist
  tags[:title] = title
  tags[:track] = track if track

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
