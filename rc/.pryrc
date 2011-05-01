#!/usr/bin/ruby
###################################################################
## Pry tweaks

puts "Loading modules..."

def req(mod)
  puts "  |_ #{mod}"
  require mod
  yield if block_given?
rescue Exception => e
  p e
end

###################################################################
## Misc Ruby libraries

#req 'open-uri'
req 'epitools'
req 'awesome_print'


## PrintMembers

req 'print_members'

class Object
  def meths(pattern=//)
    PrintMembers.print_members(self, pattern)
  end
end


## Sketches

req 'sketches' do
  Sketches.config :editor => 'j'
end


## Pry commands

#class MyCommands < Pry::Commands
Pry::Commands.class_eval do
  #alias_command "?", "show-doc"
  #alias_command ">", "cd"
  #alias_command "<", "cd .."
  command("decode") { |uri| puts URI.decode(uri) }
  
  
  command "gem", "rrrrrrrrrubygems!" do |*args|
    gem_home = Gem.instance_variable_get(:@gem_home)
  
    command = ["gem"] + args
    command.unshift "sudo" unless File.writable?(gem_home)
  
    output.puts "Executing: #{bright_yellow command.join(' ')}"
    if system(*command)
      Gem.refresh
      output.puts "Refreshed gem cache."
    else
      output.puts "Gem failed."
    end
  end

  alias_command "require", "req"
  
  command "ls", "List Stuff" do |*args|
    target.eval('self').meths(*args)
  end
  
end

