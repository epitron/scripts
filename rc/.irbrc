#!/usr/bin/ruby
###################################################################
## IRB tweaks

# Note: You must install these gems:
#  * hirb
#  * looksee
#  * boson
#  * bond
# (It won't tell you if they're not installed... the RC file will
#  just terminate before it's finished.)

puts "Loading modules..."

def req mod
  puts "  |_ #{mod}"
  require mod
rescue Exception => e
  p e
end

req 'irb/completion'

IRB.conf[:AUTO_INDENT] = true
IRB.conf[:USE_READLINE] = true
IRB.conf[:LOAD_MODULES] ||= []
#modules_to_load.each do |m|
#  unless IRB.conf[:LOAD_MODULES].include?(m)
#    IRB.conf[:LOAD_MODULES] << m
#  end
#end

###################################################################
## Misc Ruby libraries

req 'rubygems'
req 'pp'
req 'pathname'
req 'open-uri'
req 'epitools'

## PM

req 'print_members'

class Object
  def meths(pattern=//)
    PrintMembers.print_members(self, pattern)
  end
end

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


req 'rdoc/ri/driver'
ENV['PAGER'] = 'less -X -F -i -R'

def ri(original_query, regex=nil)
  query = original_query.to_s
  ri_driver = RDoc::RI::Driver.new(RDoc::RI::Driver.process_args([query]))

  # if query is a class ri recognizes
  if (class_cache = ri_driver.class_cache[query])
    methods = []
    class_methods = class_cache["class_methods"].map {|e| e["name"]}
    instance_methods = class_cache["instance_methods"].map {|e| e["name"]}
    if regex
      class_methods = class_methods.grep(/#{regex}/)
      instance_methods = instance_methods.grep(/#{regex}/)
    end  
    all_methods = class_methods.each {|e| methods << {:name=>"#{query}.#{e}", :type=>:class}} +
      instance_methods.each {|e| methods << {:name=>"#{query}.#{e}", :type=>:instance}}
    menu(methods, :fields=>[:name, :type]) do |chosen|
      system_ri(*chosen.map {|e| e[:name]})
    end
  else
    results = ri_driver.select_methods(/#{query}/)
    menu(results, :fields=>['full_name'], :ask=>false) do |chosen|
      system_ri(*chosen.map {|e| e['full_name']})
    end    
  end
end

###################################################################
## echo

def echo(val = true)
  val = val.truthy?
  puts "Echo #{val ? "ON" : "OFF"}"
  conf.echo = val
end

def noecho
  echo(false)
end

