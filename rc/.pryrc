#!/usr/bin/ruby
###################################################################
## Pry tweaks

puts "Loading modules..."

def req mod
  puts "  |_ #{mod}"
  require mod
rescue Exception => e
  p e
end

###################################################################
## Misc Ruby libraries

#req 'open-uri'
req 'epitools'

## PM

req 'print_members'

class Object
  def meths(pattern=//)
    PrintMembers.print_members(self, pattern)
  end
end


## Pry aliases
#class MyCommands < Pry::Commands
Pry::Commands.class_eval do
  
  #alias_command "?", "show-doc"
  #alias_command ">", "cd"
  #alias_command "<", "cd .."
  
end

## Other stuff

def src(str)
  case str
    when /^(.+)[\.#](.+)$/
      obj = eval $1
      method = $2.to_sym
      
      puts
      print "=> ".light_red
      puts "#{obj.inspect}##{method}".light_cyan
      puts
      PrintMembers.print_source(obj, method)
    else
      puts "Dunno what #{str} is."
  end
end

