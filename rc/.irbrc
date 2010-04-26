###################################################################
## IRB tweaks

# Note: You must install these gems:
#  * hirb
#  * looksee
#  * boson
# (It won't tell you if they're not installed... the RC file will
#  just terminate before it's finished.)

require 'irb/completion'

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

require 'rubygems'
require 'pp'
require 'pathname'
require 'open-uri'


###################################################################
## Looksee!

require 'looksee/shortcuts'

class Object

  alias_method :meths, :lookup_path
  def methgrep(*args); expr = args.shift; lookup_path(*args).grep(expr); end
  def privmethgrep(*args); expr = args.shift; privmeths(*args).grep(expr); end
  def privmeths(*args); args.unshift(:private); lookup_path(*args); end

=begin
  # Old METHS
  def meths filter=nil
    p [:class, self.class]
    case self.class.name
      when "Class"
        ms = (self.instance_methods - Object.instance_methods)
      when "Module"
        ms = (self.methods - Object.methods)
      when "Object"
        ms = (self.methods - Object.instance_methods)
    end
    ms = ms.grep filter if filter
    ms.sort
  end
=end
end


###################################################################
## RI hack

require 'rdoc/ri/driver'
ENV['PAGER'] = 'less -X -F -i -R'
require 'boson'
Boson.start

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
  
  def system_ri(*queries)
    ::Hirb::View.capture_and_render { RDoc::RI::Driver.run(queries) }
  end



###################################################################
## Hirb Trees

extend Hirb::Console

 module InheritanceTree
    # Retrieves objects of the current class.
    def objects
      class_objects = []
      ObjectSpace.each_object(self) {|e| class_objects << e }
      class_objects
    end
    
    # Retrives immediate subclasses of the current class.
    def class_children
      (@class_objects ||= Class.objects).select {|e| e.superclass == self }
    end
  end
  
  Module.send :include, InheritanceTree

 module NestedTree
    # Since nested classes are just constants:
    def nested_children
      constants.map {|e| const_get(e) }.select {|e| e.is_a?(Module) } - [self]
    end
    
    def nested_name
      self.to_s.split(":")[-1]
    end
  end
  
  Module.send :include, NestedTree


def tree(thing)
  view thing, :class=>:parent_child_tree, :children_method=>:nested_children, :type=>:directory, :value_method=>:nested_name
end

###################################################################
## Truthy

class Object

  #
  # Is this object something that can be construed as "true"?
  #
  def truthy?
    case self.to_s.downcase
      when "1", "on", "true", "enabled"
        true
      when "0", "off", "false", "disabled", ""
        false
    else
      raise "Unknown truthiness: #{self.inspect}"
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


###################################################################
## DONE!

puts "irbrc complete!"



