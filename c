#!/usr/bin/env ruby
##############################################################################
#
# TODOs:
#   * Make .ANS files work in 'less' (less -S -R, cp437)
#   * Refactor into "filters" and "renderers", with one core loop to dispatch
#     (eg: special rules for when a shebang starts the file)
#
##############################################################################
require 'coderay'
require 'coderay_bash'
##############################################################################

THEMES = {
  siberia: {:class=>"\e[34;1m", :class_variable=>"\e[34;1m", :comment=>"\e[33m", :constant=>"\e[34;1m", :error=>"\e[37;44m", :float=>"\e[33;1m", :global_variable=>"\e[33;1m", :inline_delimiter=>"\e[32m", :instance_variable=>"\e[34;1m", :integer=>"\e[33;1m", :keyword=>"\e[36m", :method=>"\e[36;1m", :predefined_constant=>"\e[36;1m", :symbol=>"\e[36m", :regexp=>{:modifier=>"\e[36m", :self=>"\e[34;1m", :char=>"\e[36;1m", :content=>"\e[34;1m", :delimiter=>"\e[34m", :escape=>"\e[36m"}, :shell=>{:self=>"\e[34;1m", :char=>"\e[36;1m", :content=>"\e[34;1m", :delimiter=>"\e[36m", :escape=>"\e[36m"}, :string=>{:self=>"\e[34;1m", :char=>"\e[36;1m", :content=>"\e[34;1m", :delimiter=>"\e[36m", :escape=>"\e[36m"}},
  ocean:   {:class=>"\e[38;5;11m", :class_variable=>"\e[38;5;131m", :comment=>"\e[38;5;8m", :constant=>"\e[38;5;11m", :error=>"\e[38;5;0;48;5;131m", :float=>"\e[38;5;173m", :global_variable=>"\e[38;5;131m", :inline_delimiter=>"\e[38;5;137m", :instance_variable=>"\e[38;5;131m", :integer=>"\e[38;5;173m", :keyword=>"\e[38;5;139m", :method=>"\e[38;5;4m", :predefined_constant=>"\e[38;5;131m", :symbol=>"\e[38;5;10m", :regexp=>{:modifier=>"\e[38;5;10m", :self=>"\e[38;5;10m", :char=>"\e[38;5;152m", :content=>"\e[38;5;152m", :delimiter=>"\e[38;5;10m", :escape=>"\e[38;5;137m"}, :shell=>{:self=>"\e[38;5;10m", :char=>"\e[38;5;152m", :content=>"\e[38;5;10m", :delimiter=>"\e[38;5;10m", :escape=>"\e[38;5;137m"}, :string=>{:self=>"\e[38;5;10m", :char=>"\e[38;5;152m", :content=>"\e[38;5;10m", :delimiter=>"\e[38;5;10m", :escape=>"\e[38;5;137m"}},
  modern:  {:class=>"\e[38;5;207;1m", :class_variable=>"\e[38;5;80m", :comment=>"\e[38;5;24m", :constant=>"\e[38;5;32;1;4m", :error=>"\e[38;5;31m", :float=>"\e[38;5;204;1m", :global_variable=>"\e[38;5;220m", :inline_delimiter=>"\e[38;5;41;1m", :instance_variable=>"\e[38;5;80m", :integer=>"\e[38;5;37;1m", :keyword=>"\e[38;5;167;1m", :method=>"\e[38;5;70;1m", :predefined_constant=>"\e[38;5;14;1m", :symbol=>"\e[38;5;83;1m", :regexp=>{:modifier=>"\e[38;5;204;1m", :self=>"\e[38;5;208m", :char=>"\e[38;5;208m", :content=>"\e[38;5;213m", :delimiter=>"\e[38;5;208;1m", :escape=>"\e[38;5;41;1m"}, :shell=>{:self=>"\e[38;5;70m", :char=>"\e[38;5;70m", :content=>"\e[38;5;70m", :delimiter=>"\e[38;5;15m", :escape=>"\e[38;5;41;1m"}, :string=>{:self=>"\e[38;5;41m", :char=>"\e[38;5;41m", :content=>"\e[38;5;41m", :delimiter=>"\e[38;5;41;1m", :escape=>"\e[38;5;41;1m"}},
  solarized: {:class=>"\e[38;5;136m", :class_variable=>"\e[38;5;33m", :comment=>"\e[38;5;240m", :constant=>"\e[38;5;136m", :error=>"\e[38;5;254m", :float=>"\e[38;5;37m", :global_variable=>"\e[38;5;33m", :inline_delimiter=>"\e[38;5;160m", :instance_variable=>"\e[38;5;33m", :integer=>"\e[38;5;37m", :keyword=>"\e[38;5;246;1m", :method=>"\e[38;5;33m", :predefined_constant=>"\e[38;5;33m", :symbol=>"\e[38;5;37m", :regexp=>{:modifier=>"\e[38;5;160m", :self=>"\e[38;5;64m", :char=>"\e[38;5;160m", :content=>"\e[38;5;64m", :delimiter=>"\e[38;5;160m", :escape=>"\e[38;5;160m"}, :shell=>{:self=>"\e[38;5;160m", :char=>"\e[38;5;160m", :content=>"\e[38;5;37m", :delimiter=>"\e[38;5;160m", :escape=>"\e[38;5;160m"}, :string=>{:self=>"\e[38;5;160m", :char=>"\e[38;5;160m", :content=>"\e[38;5;37m", :delimiter=>"\e[38;5;160m", :escape=>"\e[38;5;37m"}},
}
CodeRay::Encoders::Terminal::TOKEN_COLORS.merge!(THEMES[:siberia])

def lesspipe(*args)
  if args.any? and args.last.is_a?(Hash)
    options = args.pop
  else
    options = {}
  end
  
  output = args.first if args.any?
  
  params = []
  params << "-i"
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

def which(bin)
  ENV["PATH"].split(":").find do |path|
    result = File.join(path, bin)
    return result if File.exists? result
  end
  nil
end

##############################################################################

COMPRESSORS = {
  ".gz"  => %w[gzip -d -c],
  ".xz"  => %w[xz -d -c],
  ".bz2" => %w[bzip2 -d -c],
}

def convert(arg)
  arg = which(arg) unless File.exists? arg

  if arg
    return "\e[31m\e[1mThat's a directory!\e[0m" if File.directory? arg

    ext = File.extname(arg).downcase

    if cmd = COMPRESSORS[ext]
      IO.popen([*cmd, arg])
    elsif %w[.md .markdown].include? ext
      convert_markdown(arg)
    elsif %w[.nfo .ans .drk .ice].include? ext
      convert_cp437(arg)
    else
      convert_coderay(arg)
    end
  else
    "\e[31m\e[1mFile not found.\e[0m"
  end
end

### Converters ###############################################################

EXTRA_LANGS = {
  ".qml" => :php,
  ".pro" => :sql,
  ".service" => :ini,
  "PKGBUILD" => :bash,
  ".install" => :bash,
  "Makefile" => :bash,
  "Rakefile" => :ruby,
  "Gemfile" => :ruby,
  "Gemfile.lock" => :yaml,
  "database.yml" => :yaml,
  ".gradle" => :groovy,
  ".cr" => :ruby,
  ".sage" => :python,
  ".desktop" => :bash,
}

def convert_coderay(filename)
  ext = filename[/\.[^\.]+$/]

  if File.read(filename, 256) =~ /\A#!(.+)/
    # Shebang!
    lang = case $1
    when /ruby/ then :ruby
    when /\b(bash|zsh|sh)\b/ then :bash
    when /python/ then :python
    when /perl/ then :perl
    end

    CodeRay.scan_file(filename, lang).term
  else
    if ext == ".json"
      require 'json'

      json = JSON.parse(File.read(filename))
      CodeRay.scan(JSON.pretty_generate(json), :json).term
    elsif lang = (EXTRA_LANGS[ext] || EXTRA_LANGS[filename])
      # p lang: lang
      CodeRay.scan_file(filename, lang).term
    else
      CodeRay.scan_file(filename).term 
    end
  end
rescue ArgumentError
  IO.popen("file", "filename") { |io| }
end

##############################################################################

def convert_markdown(filename)
  # Lazily load markdown renderer
  eval DATA.read

  carpet = Redcarpet::Markdown.new(BlackCarpet, :fenced_code_blocks=>true)
  carpet.render(File.read filename)
end

##############################################################################

def convert_cp437(filename)
  open(filename, "r:cp437:utf-8", &:read)
end

### MAIN #####################################################################

args = ARGV

lesspipe(:wrap=>true) do |less|
  case args.size
  when 0
    puts "usage: c <filename(s)>"
  when 1
    convert(args.first).each_line { |line| less.puts line }
  else # 2 or more args
    args.each do |arg|
      less.puts "\e[30m\e[1m=== \e[0m\e[36m\e[1m#{arg} \e[0m\e[30m\e[1m==============\e[0m"
      less.puts
      convert(arg).each_line { |line| less.puts line }
      less.puts 
      less.puts
    end
  end
end


### Markdown ANSI Renderer ("BlackCarpet") ###################################

__END__

# This gets lazily loaded if markdown is to be rendered.

require 'epitools/colored'
require 'redcarpet'

def indented?(text)
  indent_sizes = text.lines.map{ |line| if line =~ /^(\s+)/ then $1 else '' end }.map(&:size)
  indent_sizes.all? {|dent| dent > 0 }  
end

def unwrap(text)
  return text unless indented? text
  text.lines.to_a.map(&:strip).join ' '
end

def indent(text,amount=2)
  text.lines.map{|line| " "*amount + line }.join
end

class BlackCarpet < Redcarpet::Render::Base

  def normal_text(text)
    text
  end

  def raw_html(html)
    ''
  end
  
  def link(link, title, content)
    unless content[/^Back /]
      "<15>#{content}</15> <8>(</8><9>#{link}</9><8>)</8>".colorize
    end
  end
  
  def block_code(code, language)
    language ||= :ruby
    require 'coderay'
    "#{indent CodeRay.scan(code, language).term, 4}\n"
  end
  
  def block_quote(text)
    indent paragraph(text)
  end

  def codespan(code)
    code.cyan
  end

  def header(title, level, anchor=nil)
    color = case level
      when 1 then :light_yellow
      when 2 then :light_cyan
      when 3 then :light_blue
      else :purple
    end
    
    bar = ("-"*(title.size+4)).grey
    
    "#{bar}\n  #{title.send(color)}\n#{bar}\n\n"    
  end

  def double_emphasis(text)
    text.light_green
  end

  def emphasis(text)
    text.green
  end

  def linebreak
    "\n"
  end

  def paragraph(text)
    "#{indented?(text) ? text : unwrap(text)}\n\n"
  end

  def list(content, list_type)
    case list_type
    when :ordered
      @counter = 0
      "#{content}\n"
    when :unordered
      "#{content}\n"
    end
  end

  def list_item(content, list_type)
    case list_type
    when :ordered
      @counter ||= 0
      @counter += 1
      "  <8>#{@counter}.</8> #{content.strip}\n".colorize
    when :unordered
      "  <8>*</8> #{content.strip}\n".colorize
    end
  end
end
