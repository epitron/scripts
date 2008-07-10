#!/usr/bin/env ruby

## Load Modules

begin

  # pull in some tasty code
  %w(rubygems colorize).each { |gem| require(gem) }

  class Object
    def hilite(query)
      self.to_s.gsub(/(.*)(#{query})(.*)/) { $1.green + $2.black.on_yellow + $3.green }
    end
  end

rescue LoadError

  class Object
    def hilite(query)
      self
    end
  end

end


## Display Help (if requested)

if ["--help", "-h"].include?(ARGV[0])
  puts DATA.read
  exit
end


## Parse Commandline

query = Regexp.new(Regexp.escape(ARGV.any? ? ARGV.shift : ""))
roots = (ARGV.any? ? ARGV : ['.']).select { |path| File.directory? path }


## Search/display files

roots.each do |root|
  Dir["#{root}/**/*"].each do |path|
    #p path
    dirname, filename = File.split(path)
    puts "#{dirname}/#{filename.hilite(query)}" if filename =~ query
  end
end

__END__
"f" (c) 2002-2008 by Chris Gahan (chris@ill-logic.com)

Usage:
  f                         => recursively list all files in current directory
  f <search string>         => recursively list all files in current directory
                               containing <search string>
  f <search string> <paths> => recursively list all files in <paths>
                               containing <search string>

