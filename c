#!/usr/bin/env ruby
##############################################################################
require 'coderay'
##############################################################################

def lesspipe(*args)
  if args.any? and args.last.is_a?(Hash)
    options = args.pop
  else
    options = {}
  end
  
  output = args.first if args.any?
  
  params = []
  params << "-R" unless options[:color] == false
  params << "-S" unless options[:wrap] == true
  params << "-F" unless options[:always] == true
  if options[:tail] == true
    params << "+\\>"
    $stderr.puts "Seeking to end of stream..."
  end
  params << "-X"
  
  IO.popen("less #{params * ' '}", "w") do |less|
    if output
      less.puts output
    else
      yield less
    end
  end
  
rescue Errno::EPIPE, Interrupt
  # less just quit -- eat the exception.
end

##############################################################################

args = ARGV

if args.any?
  args.each do |arg|
    lesspipe() { |less| less.puts CodeRay.scan_file(arg).term }
  end
else
  lesspipe() { |less| less.puts CodeRay.scan($stdin).term }
end
