modules_to_load = ['irb/completion', 'rubygems']

IRB.conf[:AUTO_INDENT] = true
IRB.conf[:USE_READLINE] = true
IRB.conf[:LOAD_MODULES] ||= []
modules_to_load.each do |m|
  unless IRB.conf[:LOAD_MODULES].include?(m)
    IRB.conf[:LOAD_MODULES] << m
  end
end

require 'pp'
require 'pathname'

class Object
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
end

puts "Loaded"
