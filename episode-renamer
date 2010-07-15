#!/usr/bin/ruby

@dirs    = ARGV || ["."]
@season  = 0
@episode = 0

@dirs.each do |d|
  Dir.entries(d).each do |e|
    if(e.match(/.*[sS]([0-9]{1,2})[eE]([0-9]{1,2}).*/))
      @season  = $1.to_i
      @episode = $2.to_i
    elsif(e.match(/.*([0-9]{3}).*/))
      @season  = $1.to_i / 100
      @episode = $1.to_i % 100
    else
      next
    end

    begin
      File.rename(File.join(d, e), "%s/s%.2de%.2d.avi" % [ d, @season, @episode ])
    rescue
      puts e
      puts $!
    end
  end
end
