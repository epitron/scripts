# #!/usr/bin/ruby

return if defined? Rails

Bond.config[:debug] = true if defined? Bond

# theme
# Pry.config.theme = "vim-detailed"
# Pry.config.theme = "tomorrow"
# Pry.config.theme = "solarized"
Pry.config.theme = "pry-siberia-16"

# Pry.config.theme = "zenburn"
# Pry.config.theme = "pry-classic-256"
# Pry.config.theme = "twilight"


###################################################################
## Gem Loader

puts "Loading gems..."

def req(mod)
  puts "  |_ #{mod}"
  require mod
  yield if block_given?
rescue Exception => e
  p e
end

###################################################################
## Misc Ruby libraries

req 'epitools'

# req 'awesome_print' do

#   AwesomePrint.pry!

#   # autoreq :Nokogiri do
#   #   require 'awesome_print/ext/nokogiri'
#   #   require 'nokogiri'
#   # end
  
#   # # awesomeprint output
#   # Pry.config.print = proc do |output, value|
#   #   pretty = value.ai(:indent=>2)
#   #   #Pry::Helpers::BaseHelpers.paged_output("=> #{pretty}", :output=>output)
#   #   Pry::Helpers::BaseHelpers.stagger_output("=> #{pretty}", output)
#   # end
# end

# req 'coolline' do
#   req 'coderay' do

#     Pry.config.input = Coolline.new do |c|

#       c.word_boundaries += ["."]

#       c.transform_proc = proc do
#         CodeRay.scan(c.line, :ruby).term
#       end

#       c.completion_proc = proc do
#         word = c.completed_word
#         Object.constants.map(&:to_s).select { |w| w.start_with? word }
#       end
#     end

#   end
# end

###################################################################
## History

PRY_CONFIG_DIR = File.expand_path("~/.pry")

Pry.history.loader = proc do |&block|
  Dir["#{PRY_CONFIG_DIR}/history-*.log"].sort_by { |f| File.mtime f }.last(2).each do |fn|
    File.foreach(fn) { |line| block.call(line) }
  end
end
 
# history_file = nil
 
Pry.history.saver = proc do |line|
  if !@history_file
    Dir.mkdir(PRY_CONFIG_DIR) unless File.exists?(PRY_CONFIG_DIR)
    filename = "#{PRY_CONFIG_DIR}/history-#{Time.now.strftime('%Y-%m-%d')}.log"
    @history_file = File.open(filename, 'a', 0600).tap { |f| f.sync = true }
  end
  @history_file.puts(line)
end



# friendly prompt
=begin
name = "pry" #app.class.parent_name.underscore
colored_name = Pry::Helpers::Text.blue(name)
raquo = Pry::Helpers::Text.red("\u00BB")
line = ->(pry) { "[#{Pry::Helpers::Text.bold(pry.input_array.size)}] " }
target_string = ->(object, level) do
  unless (string = Pry.view_clip(object)) == 'main'
    "(#{'../' * level}#{string})"
  else
    ''
  end
end

Pry.config.prompt = [
  ->(object, level, pry) do
    "#{line.(pry)}#{colored_name}#{target_string.(object, level)} #{raquo}  "
  end,
  ->(object, level, pry) do
    spaces = ' ' * (
      "[#{pry.input_array.size}] ".size +  # Uncolored `line.(pry)`
      name.size +
      target_string.(object, level).size
    )
    "#{spaces} #{raquo}  "
  end
]
=end

## PrintMembers
# req 'print_members' do
#   Pry.commands.instance_eval do
#     rename_command "oldls", "ls"
#     command "ls", "Better ls" do |arg|
#       #if target.eval(arg)
#       query = arg ? Regexp.new(arg, Regexp::IGNORECASE) : //
#       PrintMembers.print_members(target.eval("self"), query)
#     end
#   end
# end

# Pry.commands.command(/^wtf([?!]*)/, "show backtrace") do |arg|
#   raise Pry::CommandError, "No most-recent exception" unless _pry_.last_exception
#   output.puts _pry_.last_exception
#   output.puts _pry_.last_exception.backtrace.first([arg.size, 0.5].max * 10)
# end

## Sketches

#req 'sketches' do
#  Sketches.config :editor => 's'
#end

=begin
req 'rdoc/ri/driver' do

  class RDoc::RI::Driver
    def page
      lesspipe {|less| yield less}
    end

    def formatter(io)
      if @formatter_klass then
        @formatter_klass.new
      else
        RDoc::Markup::ToAnsi.new
      end
    end
  end

  Pry.commands.command "ri", "RI it up!" do |*names|
    ri = RDoc::RI::Driver.new :use_stdout => true, :interactive => false
    ri.display_names names
  end

end
=end


###################################################################
# ri

# Pry.commands.command "ri", "RI it up!" do |*names|
#   require 'rdoc/ri/driver'

#   unless RDoc::RI::Driver.responds_to? :monkeypatched?
#     class RDoc::RI::Driver
#       def page
#         lesspipe {|less| yield less}
#       end

#       def formatter(io)
#         if @formatter_klass then
#           @formatter_klass.new
#         else
#           RDoc::Markup::ToAnsi.new
#         end
#       end

#       def monkeypatched?
#         true
#       end
#     end
#   end

#   ri = RDoc::RI::Driver.new :use_stdout => true, :interactive => false

#   begin
#     ri.display_names names
#   rescue RDoc::RI::Driver::NotFoundError => e
#     $stderr.puts "error: '#{e.name}' not found"
#   end

# end


###################################################################
# Colours

module Pry::Helpers::Text
  class << self
    alias_method :grey, :bright_black
    alias_method :gray, :bright_black
  end
end



###################################################################
# Other stuff

Pry.commands.instance_eval do

  alias_command("@", "whereami")
  alias_command("stack", "show-stack") rescue nil

  command "gem-search" do |*args|
    require 'open-uri'

    query   = args.join ' '
    results = open("http://rubygems.org/api/v1/search.json?query=#{query.urlencode}").read.from_json

    if !results.is_a?(Array) || results.empty?
      output.puts 'No results'
    else
      for result in results
        output.puts "#{''.red}<11>#{result["name"]} <8>(<9>#{result["version"]}<8>)".colorize
        output.puts "  <7>#{result["info"]}".colorize
      end
    end
  end

  command "grep" do |*args|

    queries = []
    targets = []

    args.each do |arg|

      case arg
      when %r{^/([^/]+)/$}
        queries << Regexp.new($1)
      when %r{^([A-Z]\w+)$}
        targets << Object.const_get($1)
      else
      end

    end

    p [:queries, queries]
    p [:targets, targets]
  end

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

  command "pwd" do
    puts Dir.pwd.split("/").map{|s| text.bright_green s}.join(text.grey "/")
  end

  #alias_command "gems", "gem-list"

  command "gem", "rrrrrrrrrubygems!" do |*args|
    gem_home = Gem.instance_variable_get(:@gem_home) || Gem.instance_variable_get(:@paths).home

    cmd = ["gem"] + args
    cmd.unshift "sudo" unless File.writable?(gem_home)

    output.puts "Executing: #{text.bright_yellow cmd.join(' ')}"
    if system(*cmd)
      Gem.refresh
      output.puts "Refreshed gem cache."
    else
      output.puts "Gem failed."
    end
  end


  command "req-verbose", "Requires gem(s). No need for quotes! (If the gem isn't installed, it will ask if you want to install it.)" do |*gems|

    def tree_to_array(hash, indent=0)
      colors = [:light_white, :light_cyan, :light_blue]
      result = []
      dent = "  " * indent
      hash.each do |key,val|
        color = colors[indent] || :white
        result << dent+key.send(color)
        result += tree_to_array(val, indent+1) if val.any?
      end
      result
    end

    def print_module_tree mods
      mods = mods.select  { |mod| not mod < Exception }
      mods = mods.map     { |mod| mod.to_s.split("::") }

      mod_tree = {}
      mods.sort.each { |path| mod_tree.mkdir_p(path) }

      results = tree_to_array(mod_tree)
      table = Term::Table.new(results, :cols=>3, :vertically => true, :colored => true)
      puts table
    end

    gems = gems.join(' ').gsub(',', '').split(/\s+/)
    gems.each do |gem|
      begin

        before_modules = ObjectSpace.each_object(Module).to_a

        if require gem
          output.puts "#{text.bright_yellow(gem)} loaded"
          loaded_modules = ObjectSpace.each_object(Module).to_a - before_modules
          print_module_tree(loaded_modules)
        else
          output.puts "#{text.bright_white(gem)} already loaded"
        end

      # rescue LoadError => e

      #   if gem_installed? gem
      #     output.puts e.inspect
      #   else
      #     output.puts "#{gem.bright_red} not found"
      #     if prompt("Install the gem?") == "y"
      #       run "gem-install", gem
      #       run "req", gem
      #     end
      #   end

      end # rescue
    end # gems
  end

  alias_command "require", "req-verbose"
  alias_command "req", "req-verbose"


end


## Fancy Require w/ Modules
=begin
req 'terminal-table/import' do

  Commands.instance_eval do


    #  command "ls", "List Stuff" do |*args|
    #    target.eval('self').meths(*args)
    #  end

    def hash_mkdir_p(hash, path)
      return if path.empty?
      dir = path.first
      hash[dir] ||= {}
      hash_mkdir_p(hash[dir], path[1..-1])
    end

    def hash_print_tree(hash, indent=0)
      result = []
      dent = "  " * indent
      hash.each do |key,val|
        result << dent+key
        result += hash_print_tree(val, indent+1) if val.any?
      end
      result
    end

    helper :print_module_tree do |mods|
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
=end


