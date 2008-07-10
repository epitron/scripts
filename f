#!/usr/bin/env ruby

# pull in some tasty code
%w(rubygems colorize).each { |gem| require(gem) }

class Object
  def hilite(query)
    self.to_s.gsub(/(.*)(#{query})(.*)/) { $1.green + $2.black.on_yellow + $3.green }
  end
end

query = Regexp.new(Regexp.escape(ARGV.any? ? ARGV.shift : ""))
roots = (ARGV.any? ? ARGV : ['.']).select { |path| File.directory? path }

roots.each do |root|
  Dir["#{root}/**/*"].each do |path|
    #p path
    dirname, filename = File.split(path)
    puts "#{dirname}/#{filename.hilite(query)}" if filename =~ query
  end
end
