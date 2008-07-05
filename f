#!/usr/bin/ruby

# pull in some groovy code
%w* rubygems colorize rio *.each { |thing| require(thing) }

query = Regexp.new Regexp.escape(ARGV.shift)

class Object
  def hilite(query)
    self.to_s.gsub(/(.*)(#{query})(.*)/) { $1.green + $2.black.on_yellow + $3.green }
  end
end


paths = ARGV.any? ? ARGV : ['./']

# collect matching files and display
paths.each do |path|
  rio(path).all.select do |thing|
    # TODO: highlight the entire path segment in which the match(es)
    #       (is/are) found.
    #       eg: "/stuff/what/<i><b>amazing</b>stuff</i>/"
    
    #p thing.split
    if thing.filename =~ query
      puts thing.dirname + "/" + thing.filename.hilite(query)
    end
    
  end
end
