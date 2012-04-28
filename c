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

def render(arg)
  if arg == $stdin
    CodeRay.scan($stdin).term
  elsif File.exists? arg
    CodeRay.scan_file(arg).term
  else
    "\e[31m\e[1mFile not found.\e[0m"
  end
end

##############################################################################

args = ARGV


lesspipe do |less|
  case args.size
  when 0
    less.puts render($stdin)
  when 1
    less.puts render(args.first)
  else # 2 or more args
    args.each do |arg|
      less.puts "\e[30m\e[1m=== \e[0m\e[36m\e[1m#{arg} \e[0m\e[30m\e[1m==============\e[0m"
      less.puts
      less.puts render(arg)
      less.puts
    end
  end
end