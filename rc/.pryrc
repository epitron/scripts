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

req 'print_members' do
  class Object
    def meths(pattern=//)
      PrintMembers.print_members(self, pattern)
    end
  end
end

## Sketches

req 'sketches' do
  Sketches.config :editor => 'j'
end

class Pry
  
  def self.commands(&block)
    Pry::Commands.class_eval(&block)
  end

  def self.command(*args, &block)
    commands do
      command *args, &block
    end    
  end

  #def self.set_alias
  #end

end

Pry.commands
  #alias_command "?", "show-doc"
  #alias_command ">", "cd"
  #alias_command "<", "cd .."
  command("decode") { |uri| puts URI.decode(uri) }

  command "lls", "List local files using 'ls'" do |*args|
    cmd = ".ls"
    cmd << " --color=always" if Pry.color
    run cmd, *args
  end
  
  command "lcd", "Change the current (working) directory" do |*args|
    run ".cd", *args
    run "pwd"
  end
   
  Pry.command "pwd" do; puts Dir.pwd.split("/").map{|s| bright_green s}.join(grey "/"); end
  
  require 'rdoc/ri/driver'
  
  command "ri", "RI it up, muthafucka." do |*args|
    RDoc::RI::Driver.run args
  end
    
  alias_command "gems", "gem-list"
  
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
  
  command "ls", "Better ls" do |arg|
    query = arg ? Regexp.new(arg, Regexp::IGNORECASE) : //
    PrintMembers.print_members(target.eval("self"), query)
  end

end


## Fancy Require w/ Modules

req 'terminal-table/import' do

  class Pry::Commands
    
    command "req-verbose", "Requires gem(s). No need for quotes! (If the gem isn't installed, it will ask if you want to install it.)" do |*gems|
      gems = gems.join(' ').gsub(',', '').split(/\s+/)
      gems.each do |gem|
        begin
  
          before_modules = ObjectSpace.each_object(Module).to_a
  
          if require gem
            output.puts "#{bright_yellow(gem)} loaded"
            loaded_modules = ObjectSpace.each_object(Module).to_a - before_modules
            print_module_tree(loaded_modules)
          else
            output.puts "#{bright_white(gem)} already loaded"
          end
  
        rescue LoadError => e
  
          if gem_installed? gem
            output.puts e.inspect
          else
            output.puts "#{bright_red(gem)} not found"
            if prompt("Install the gem?") == "y"
              run "gem-install", gem
              run "req", gem
            end
          end
  
        end # rescue
      end # gems
    end
  
    alias_command "require", "req-verbose"
    
    #  command "ls", "List Stuff" do |*args|
    #    target.eval('self').meths(*args)
    #  end
    
    def self.hash_mkdir_p(hash, path)
      return if path.empty?
      dir = path.first
      hash[dir] ||= {}
      hash_mkdir_p(hash[dir], path[1..-1])
    end
    
    def self.hash_print_tree(hash, indent=0)
      result = []
      dent = "  " * indent
      hash.each do |key,val|
        result << dent+key
        result += hash_print_tree(val, indent+1) if val.any?
      end
      result
    end
    
    def self.print_module_tree(mods)
      mod_tree = {}
      mods = mods.select  { |mod| not mod < Exception }
      mods = mods.map     { |mod| mod.to_s.split("::") }
      mods.sort.each do |path|
        hash_mkdir_p(mod_tree, path)
      end
      results = hash_print_tree(mod_tree)
      table = PrintMembers::Formatter::TableDefinition.new
      results.each_slice([results.size/3, 1].max) do |slice|
        table.column(*slice)
      end
      puts table(nil, *table.rows.to_a)
    end
    
  end  
    

end


# Mon_Ouie's patches
  
class Pry::Commands

  def self.wrap_text(text, columns = 80)
    text = text.dup
    res = []

    while text.length > columns
      if text[0, columns] =~ /^(.+\s)(\S+)$/
        res << $1
        text = $2 + text[columns..-1]
      else
        res << text[0, columns]
        text[0...columns] = ''
      end
    end

    res << text
    res
  end

  def self.signature_for(info)
    sig = "#{info.name.to_s.cyan}(" + info.parameters.map { |(param, default)|
      if default
        "#{param} = #{default}"
      else
        param
      end
    }.join(", ") + ")"

    if yield_tag = info.tag("yield")
      args = yield_tag.types ? yield_tag.types.join(", ") : ""
      args = "|#{args}| " unless args.empty?

      sig << " { #{args}... }"
    end

    type = (tag = info.tag("return")) ? tag.type : "Object"
    sig << " # => #{type.yellow}"
  end

  def self.format_parameter(param)
    types = if param.types
              param.types.map { |o| o.yellow }.join(', ')
            else
              "Object"
            end

    default = if param.respond_to? :defaults and param.defaults
                " (default: #{param.defaults.join(", ")})"
              end

    text = (param.text || "").gsub("\n", "\n" + " " * 6)
    "  -- (#{types}) #{param.name.bold}#{default} #{text}"
  end

  def self.document_info(info, output)
    doc = info.docstring.split("\n")
    doc.each do |line|
      if line[0, 2] == " " * 2
        output.puts CodeRay.scan(line, :ruby).term
      else
        output.puts line
      end
    end

    if deprecated = info.tag("deprecated")
      output.puts
      output.puts "#{'DEPRECATED:'.red.bold} #{deprecated.text}"
    end

    if note = info.tag("note")
      output.puts
      output.puts "#{'NOTE:'.red.bold} #{note.text}"
    end

    if abstract = info.tag("abstract")
      output.puts
      output.puts "#{'Abstract:'.bold} #{abstract.text}"
    end

    unless info.tags("param").empty?
      output.puts
      output.puts "Parameters: ".italic
      info.tags("param").each do |param|
        output.puts format_parameter(param)
      end
    end

    unless info.tags("option").empty?
      info.tags("option").group_by(&:name).each do |name, opts|
        output.puts
        output.puts "Options for #{name.bold}: ".italic

        opts.each do |opt|
          output.puts format_parameter(opt.pair)
        end
      end
    end

    if yield_tag = info.tag("yield")
      output.puts
      output.print "#{'Yields:'.bold.italic} "
      output.puts yield_tag.text.to_s.gsub("\n", "\n  ")

      unless info.tags("yieldparam").empty?
        output.puts
        output.puts "Block arguments: ".bold.italic

        info.tags("yieldparam").each do |param|
          output.puts format_parameter(param)
        end
      end

      if ret = info.tag("yieldreturn")
        output.print "Block returns: ".bold.italic
        output.print "(#{(tag.types || %w[Object]).join(', ')}) "
        output.puts  ret.text.gsub("\n", "\n  ")
      end
    end

    unless info.tags("raise").empty?
      output.puts
      output.puts "Exceptions: ".bold

      info.tags("raise").each do |tag|
        output.print "  -- #{(ret.types || %w[Object]).join(', ')}: ".italic
        output.puts tag.text
      end
    end

    if ret = info.tag("return")
      output.print "Returns: ".bold.italic
      output.print "(#{(ret.types || %w[Object]).join(', ')}) "
      output.puts  ret.text.to_s.gsub("\n", "\n  ")
    end

    unless info.tags("example").empty?
      info.tags("example").each do |ex|
        output.puts
        output.puts "Example: #{ex.name.bold}:".italic

        code = "  " + CodeRay.scan(ex.text, :ruby).term.gsub("\n", "\n  ")
        output.puts code
      end
    end

    unless info.tags("see").empty?
      output.puts
      output.puts "See also: ".bold

      info.tags("see").each do |tag|
        output.puts " -- #{tag.text}"
      end
    end

    if author = info.tag("author")
      output.puts
      output.puts "#{'Author:'.bold} #{author.text}"
    end
  end

end



