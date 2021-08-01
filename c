#!/usr/bin/env ruby
##############################################################################
#
# StarCat (aka. *cat) -- print every file format, in beautiful ANSI colour!
#
# Optional dependencies:
#
#   ruby gems:
#     redcloth (for markdown)
#     nokogiri (for wikidumps)
#     rougify (for source code)
#
#   python packages:
#     pygments
#     rst2ansi
#     docutils
#
#   ...and many more! (the script will blow up when you need that program! :D)
#
#
# TODOs:
#   * If 'file' isn't installed, fall back to using the file extension, or the mime_magic gem
#   * Refactor into "filters" (eg: gunzip) and "renderers" (eg: pygmentize) and "identifiers" (eg: ext, shebang, magic)
#     |_ all methods take a Pathname or String or Enumerable
#     |_ keep filtering the file until a renderer can be used on it (some files need to be identified by their data, not their extension)
#     |_ eg: `def convert({stream,string}, format: ..., filename: ...)` (allows chaining processors, eg: .diff.gz)
#   * Auto-install gems/pips/packages required to view a file
#   * Live filtering (grep within output chunks, but retain headers; retain some context?)
#   * Follow symbolic links (eg: c libthing.so -> libthing.so.2)
#   * "--summary" option to only print basic information about each file
#   * Change `print_*` methods to receive a string (raw data) or a Pathname/File object
#   * Follow symlinks by default
#   * "c directory/" should print "=== directory/README.md ========" in the filename which is displayed in multi-file mode
#   * Print [eof] between files when in multi-file mode
#   * Make .ANS files work in 'less' (less -S -R, cp437)
#   * Add gem/program dependencies to functions (using a DSL)
#     |_ "install all dependencies" can use it
#     |_ error/warning when dependency isn't installed, plus a fallback codepath
#   * Fix "magic" (use hex viewer when format isn't recognized)
#   * Renderers should pick best of coderay/rugmentize/pygmentize/rougify (a priority list for each ext)
#
##############################################################################
require 'pathname'
require 'coderay'
require 'coderay_bash'
require 'set'
##############################################################################

def pygmentize(lexer=nil, style="native", formatter="terminal256")
  #depends bins: "pygments"

  # Commandline options: https://www.complang.tuwien.ac.at/doc/python-pygments/cmdline.html
  #       Style gallery: https://help.farbox.com/pygments.html
  #                     (good ones: monokai, native, emacs)
  cmd = [
    "pygmentize",
    "-O", "style=#{style}",
   "-f", formatter,
  ]
  cmd += ["-l", lexer] if lexer

  cmd
end

def rougify(lexer=nil)
  # themes:   molokai  monokai.sublime   base16.solarized.dark   base16.dark   thankful_eyes
  #depends gem: "rouge"
  # TODO: fix this `cmd` mess so that the dependency check happens once the filetype has been identified

  cmd = ["rougify"]
  cmd += ["-t", "base16.dark"]
  # cmd += ["-t", "monokai.sublime"]
  # cmd += ["-t", "molokai"]
  # cmd += ["-t", "base16.solarized.dark"]
  cmd += ["-l", lexer.to_s] if lexer
  cmd
end


def render_rouge(input, lexer=nil, theme="base16.dark")
  depends gem: "rouge"
  require 'rouge'

  if input.is_a?(Pathname)
    lexer  = Rouge::Lexer.guess(filename: input.to_s) # options: filename:, source:, mimetype:
    source = input.read
  else
    lexer  = Rouge::Lexer.find(lexer)
    source = input
  end

  return source if lexer.nil?

  formatter = Rouge::Formatters::Terminal256.new(theme: Rouge::Theme.find(theme))
  formatter.format(lexer.lex(source))
end

def render_pandoc(input, from=nil, to=nil)
  depends bin: "pandoc"

  source = input.to_source
  cmd    = ["pandoc", "-f", from, "-t", to]

  IO.popen(cmd, "w+") do |io|
    io.puts source
    io.close_write
    io.read
  end
end

def which(cmd)
  ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
    exe = File.join(path, cmd)
    return exe if File.executable? exe
  end
  nil
end

class MissingDependency < Exception; end

def depends(bin: nil, bins: [], gem: nil, gems: [])
  gems = [gems].flatten
  bins = [bins].flatten
  bins << bin if bin
  gems << gem if gem
  missing = (
    bins.map { |bin| [:bin, bin] unless which(bin) } +
    gems.map do |g|
      begin
        gem(g)
        nil
      rescue Gem::MissingSpecError => e
        [:gem, g]
      end
    end
  ).compact

  if missing.any?
    msg = "Missing dependenc(y/ies): #{ missing.map{|t,n| "#{n} (#{t})"}.join(", ")}"
    raise MissingDependency.new(msg)
    # $stderr.puts msg
    # exit 1
  end
end

# def bat(lexer=nil)
#   cmd = ["bat", "--color=always"]
#   cmd += ["-l", lexer] if lexer
#   cmd
# end

### Special-case Converters ###############################################################

EXT_HIGHLIGHTERS = {
  # crystal
  ".cr"             => :ruby,

  # julia
  ".jl"             => :ruby,

  # perl
  ".pl"             => :ruby,

  # (c)make
  ".cmake"          => :ruby,
  ".mk"             => :bash,

  # gn (chromium build thing)
  ".gn"             => :bash,
  ".gni"            => :bash,

  # xdg
  ".install"        => :bash,
  ".desktop"        => :bash,

  # configs
  ".conf"           => :bash,
  ".ini"            => :bash,
  ".prf"            => :bash,
  ".ovpn"           => :bash,
  ".rc"             => :c,
  ".service"        => :bash,
  ".nix"            => rougify,

  # haskell
  ".hs"             => :text,

  # lisp
  ".cl"             => :c,
  ".lisp"           => :clojure,
  ".scm"            => :clojure,
  ".rkt"            => rougify(:racket),
  ".scrbl"          => rougify(:racket),

  # gl
  ".shader"         => :c,
  ".glsl"           => :c,

  # rust
  ".rs"             => pygmentize,
  ".toml"           => rougify,

  # asm
  ".s"              => pygmentize, # assembler

  # matlab
  ".m"              => pygmentize(:matlab),
  ".asv"            => pygmentize(:matlab),

  # dart
  ".dart"           => :java,

  # zig
  ".zig"            => pygmentize(:rust),

  # pythonic javascript (rapydscript-ng)
  ".pyj"            => :python,

  # java
  ".gradle"         => :groovy,
  ".sage"           => :python,
  ".qml"            => :php,
  ".pro"            => :sql,
  ".cxml"           => :xml,

  # llvm
  ".ll"             => rougify,

  # systemtap
  ".stp"            => :javascript,

  # caml
  ".ml"             => pygmentize,

  # nim
  ".nim"            => rougify,
  ".nimble"         => rougify(:nim),
  ".gd"             => rougify(:nim),

  # v
  ".v"              => rougify(:dart),

  # ada
  ".ada"            => rougify,
  ".ads"            => rougify,
  ".adb"            => rougify,
  ".gpr"            => rougify,
  ".adc"            => rougify(:ada),

  # factor
  '.factor'         => rougify,

  # patch
  ".diff"           => pygmentize,
  ".patch"          => pygmentize,

  # sublime
  ".tmLanguage"     => :xml,
  ".sublime-syntax" => :yaml,

  # haxe
  ".hx"             => rougify,

  # misc
  ".inc"            => :c, # weird demo stuff
  ".rl"             => :c, # ragel definitions
  ".ino"            => :c, # arduino sdk files
  ".f"              => pygmentize(:forth),

  # xml stuff
  ".ws"             => :xml,
  ".nzb"            => :xml,
  ".owl"            => :xml,
  ".ui"             => :xml,
  ".opml"           => :xml,
  ".dfxp"           => :xml,
  ".xspf"           => :xml,
  ".smil"           => :xml,
  ".xsl"            => :xml,
  ".plist"          => :xml,
  ".svg"            => :xml,
}

FILENAME_HIGHLIGHTERS = {
  "Rakefile"       => :ruby,
  "Gemfile"        => :ruby,
  "CMakeLists.txt" => :ruby,
  "Makefile"       => :bash,
  "Dockerfile"     => :bash,
  "Kconfig"        => :bash,
  "Kconfig.name"   => :bash,
  "makefile"       => :bash,
  "PKGBUILD"       => :bash,
  "template"       => :bash,
  "configure.in"   => :bash,
  "configure"      => :bash,
  "Gemfile.lock"   => :c,
  "database.yml"   => :yaml,
  "default.nix"    => rougify,
}

#
# All files that ctags can parse
#
CTAGS_EXTS = if which("ctags")
  Set.new %w[
    .1 .2 .3 .3pm .3stap .4 .5 .6 .7 .7stap .8 .9 .a51 .ac .ada .adb .adoc .ads .am .ant
    .as .asa .ash .asm .asp .au3 .aug .automount .awk .bas .bash .bat .bb .bet .bi .bsh .c .cbl
    .cc .cl .clisp .clj .cljc .cljs .cmake .cmd .cob .cp .cpp .cs .css .ctags .cu .cuh .cxx .d .device
    .di .diff .dtd .dts .dtsi .e .el .elm .erl .ex .exp .exs .f .f03 .f08 .f15 .f77 .f90 .f95 .fal
    .for .ftd .ftn .fy .gawk .gdb .gdbinit .glade .go .h .hh .hp .hpp .hrl .hx .hxx .in .ini
    .inko .inl .itcl .java .js .jsx .ksh .l .ld .ldi .lds .lisp .lsp .lua .m .m4 .mak .mawk
    .mk .ml .mli .mm .mod .mount .mxml .myr .p .p6 .pas .patch .path .pb .perl .ph .php .php3 .php4
    .php5 .php7 .phtml .pl .pl6 .plist .plx .pm .pm6 .pod .pom .pp .properties .proto .pxd .pxi .py .pyx .q .r
    .rb .rc .repo .rest .rexx .rng .robot .rs .rst .ruby .rx .s .sch .scheme .scm .scons .scope .scr .sh
    .sig .sl .slice .sm .sml .snapshot .socket .spec .spt .sql .stp .stpm .sv .svg .svh .svi .swap .target .tcl .tex
    .time .tk .ts .ttcn .ttcn3 .unit .v .varlink .vba .vhd .vhdl .vim .vr .vrh .vri .wish .wsgi
    .y .zep .zsh
  ]
else
  Set.new
end

# #
# # CTags mapping from all { '.ext' => 'LanguageName' }s
# #
# CTAGS_EXTS = if which("ctags")
#   `ctags --list-maps`.
#     each_line.
#     flat_map do |line|
#       lang, *exts = line.strip.split(/\s+/)
#       exts.map! { |ext| ext[/\.\w+$/]&.downcase }.compact.uniq
#       exts.map { |ext| [ext, lang] }
#     end.
#     to_h
# else
#   {}
# end


HTML_ENTITIES = {
  '&lt;'    => '<',
  '&gt;'    => '>',
  '&nbsp;'  => ' ',
  '&ndash;' => '-',
  '&mdash;' => '-',
  '&amp;'   => '&',
  '&raquo;' => '>>',
  '&laquo;' => '<<',
  '&quot;'  => '"',
  '&micro;' => 'u',
  '&copy;'  => '(c)',
  '&trade;' => '(tm)',
  '&reg;'   => '(R)',
  '&#174;'  => '(R)',
  '&#8220;' => '"',
  '&#8221;' => '"',
  '&#8211;' => "-",
  '&#8212;' => '--',
  '&#8230;' => '...',
  '&#39;'   => "'",
  '&#8217;' => "'",
  '&#8216;' => "'",
  '&#62;'   => ">",
  '&#60;'   => "<",
}

THEMES = {
  siberia:   {:class=>"\e[34;1m", :class_variable=>"\e[34;1m", :comment=>"\e[33m", :constant=>"\e[34;1m", :error=>"\e[37;44m", :float=>"\e[33;1m", :global_variable=>"\e[33;1m", :inline_delimiter=>"\e[32m", :instance_variable=>"\e[34;1m", :integer=>"\e[33;1m", :keyword=>"\e[36m", :method=>"\e[36;1m", :predefined_constant=>"\e[36;1m", :symbol=>"\e[36m", :regexp=>{:modifier=>"\e[36m", :self=>"\e[34;1m", :char=>"\e[36;1m", :content=>"\e[34;1m", :delimiter=>"\e[34m", :escape=>"\e[36m"}, :shell=>{:self=>"\e[34;1m", :char=>"\e[36;1m", :content=>"\e[34;1m", :delimiter=>"\e[36m", :escape=>"\e[36m"}, :string=>{:self=>"\e[34;1m", :char=>"\e[36;1m", :content=>"\e[34;1m", :delimiter=>"\e[36m", :escape=>"\e[36m"}},
  ocean:     {:class=>"\e[38;5;11m", :class_variable=>"\e[38;5;131m", :comment=>"\e[38;5;8m", :constant=>"\e[38;5;11m", :error=>"\e[38;5;0;48;5;131m", :float=>"\e[38;5;173m", :global_variable=>"\e[38;5;131m", :inline_delimiter=>"\e[38;5;137m", :instance_variable=>"\e[38;5;131m", :integer=>"\e[38;5;173m", :keyword=>"\e[38;5;139m", :method=>"\e[38;5;4m", :predefined_constant=>"\e[38;5;131m", :symbol=>"\e[38;5;10m", :regexp=>{:modifier=>"\e[38;5;10m", :self=>"\e[38;5;10m", :char=>"\e[38;5;152m", :content=>"\e[38;5;152m", :delimiter=>"\e[38;5;10m", :escape=>"\e[38;5;137m"}, :shell=>{:self=>"\e[38;5;10m", :char=>"\e[38;5;152m", :content=>"\e[38;5;10m", :delimiter=>"\e[38;5;10m", :escape=>"\e[38;5;137m"}, :string=>{:self=>"\e[38;5;10m", :char=>"\e[38;5;152m", :content=>"\e[38;5;10m", :delimiter=>"\e[38;5;10m", :escape=>"\e[38;5;137m"}},
  modern:    {:class=>"\e[38;5;207;1m", :class_variable=>"\e[38;5;80m", :comment=>"\e[38;5;24m", :constant=>"\e[38;5;32;1;4m", :error=>"\e[38;5;31m", :float=>"\e[38;5;204;1m", :global_variable=>"\e[38;5;220m", :inline_delimiter=>"\e[38;5;41;1m", :instance_variable=>"\e[38;5;80m", :integer=>"\e[38;5;37;1m", :keyword=>"\e[38;5;167;1m", :method=>"\e[38;5;70;1m", :predefined_constant=>"\e[38;5;14;1m", :symbol=>"\e[38;5;83;1m", :regexp=>{:modifier=>"\e[38;5;204;1m", :self=>"\e[38;5;208m", :char=>"\e[38;5;208m", :content=>"\e[38;5;213m", :delimiter=>"\e[38;5;208;1m", :escape=>"\e[38;5;41;1m"}, :shell=>{:self=>"\e[38;5;70m", :char=>"\e[38;5;70m", :content=>"\e[38;5;70m", :delimiter=>"\e[38;5;15m", :escape=>"\e[38;5;41;1m"}, :string=>{:self=>"\e[38;5;41m", :char=>"\e[38;5;41m", :content=>"\e[38;5;41m", :delimiter=>"\e[38;5;41;1m", :escape=>"\e[38;5;41;1m"}},
  solarized: {:class=>"\e[38;5;136m", :class_variable=>"\e[38;5;33m", :comment=>"\e[38;5;240m", :constant=>"\e[38;5;136m", :error=>"\e[38;5;254m", :float=>"\e[38;5;37m", :global_variable=>"\e[38;5;33m", :inline_delimiter=>"\e[38;5;160m", :instance_variable=>"\e[38;5;33m", :integer=>"\e[38;5;37m", :keyword=>"\e[38;5;246;1m", :method=>"\e[38;5;33m", :predefined_constant=>"\e[38;5;33m", :symbol=>"\e[38;5;37m", :regexp=>{:modifier=>"\e[38;5;160m", :self=>"\e[38;5;64m", :char=>"\e[38;5;160m", :content=>"\e[38;5;64m", :delimiter=>"\e[38;5;160m", :escape=>"\e[38;5;160m"}, :shell=>{:self=>"\e[38;5;160m", :char=>"\e[38;5;160m", :content=>"\e[38;5;37m", :delimiter=>"\e[38;5;160m", :escape=>"\e[38;5;160m"}, :string=>{:self=>"\e[38;5;160m", :char=>"\e[38;5;160m", :content=>"\e[38;5;37m", :delimiter=>"\e[38;5;160m", :escape=>"\e[38;5;37m"}},
}
CodeRay::Encoders::Terminal::TOKEN_COLORS.merge!(THEMES[:siberia])

##############################################################################
# Monkeypatches
##############################################################################

class Pathname

  include Enumerable

  alias_method :to_source, :read

  def each
    return to_enum(:each) unless block_given?
    each_line { |line| yield line.chomp }
  end

  def filename
    basename.to_s
  end
  alias_method :name, :filename

end

##############################################################################

class String

  alias_method :to_source, :to_s

  #
  # Converts time duration strings (mm:ss, mm:ss.dd, hh:mm:ss, or dd:hh:mm:ss) to seconds.
  # (The reverse of Integer#to_hms)
  #
  def from_hms
    nums = split(':')

    nums[-1] = nums[-1].to_f if nums[-1] =~ /\d+\.\d+/ # convert fractional seconds to a float
    nums.map! { |n| n.is_a?(String) ? n.to_i : n } # convert the rest to integers

    nums_and_units = nums.reverse.zip %w[seconds minutes hours days]
    nums_and_units.map { |num, units| num.send(units) }.sum
  end

end

##############################################################################

class Numeric

  def commatize(char=",")
    int, frac = to_s.split(".")
    int = int.gsub /(\d)(?=\d{3}+(?:\.|$))(\d{3}\..*)?/, "\\1#{char}\\2"

    frac ? "#{int}.#{frac}" : int
  end

  #
  # Time methods
  #
  {

    'second'  => 1,
    'minute'  => 60,
    'hour'    => 60 * 60,
    'day'     => 60 * 60 * 24,
    'week'    => 60 * 60 * 24 * 7,
    'month'   => 60 * 60 * 24 * 30,
    'year'    => 60 * 60 * 24 * 365,

  }.each do |unit, scale|
    define_method(unit)     { self * scale }
    define_method(unit+'s') { self * scale }
  end

end

##############################################################################

class Array
  #
  # Transpose an array that could have rows of uneven length
  #
  def transpose_with_padding
    max_width = map(&:size).max
    map { |row| row.rpad(max_width) }.transpose
  end

  #
  # Extend the array the target_width by adding nils to the end (right side)
  #
  def rpad!(target_width)
    if target_width > size and target_width > 0
      self[target_width-1] = nil
    end
    self
  end

  #
  # Return a copy of this array which has been extended to target_width by adding nils to the end (right side)
  #
  def rpad(target_width)
    dup.rpad!(target_width)
  end
end

##############################################################################

class Object

  def ensure_string
    is_a?(String) ? self : to_s
  end

end

##############################################################################

def convert_htmlentities(s)
  s.gsub(/&[#\w]+;/) { |m| HTML_ENTITIES[m] || m }
end

def print_header(title, level=nil)
  colors = ["\e[33m\e[1m%s\e[0m", "\e[36m\e[1m%s\e[0m", "\e[34m\e[1m%s\e[0m", "\e[35m%s\e[0m"]
  level  = level ? (level-1) : 0
  color  = colors[level] || colors[-1]
  grey   = "\e[30m\e[1m%s\e[0m"

  bar = grey % ("-"*(title.size+4))

  "#{bar}\n  #{color % title}\n#{bar}\n\n"
end

def run(*args, &block)
  return Enumerator.new { |y| run(*args) { |io| io.each_line { |line| y << line } } } unless block_given?

  opts = (args.last.is_a? Hash) ? args.pop : {}
  args = [args.map(&:ensure_string)]

  if opts[:stderr]
    args << {err: [:child, :out]}
  elsif opts[:noerr]
    args << {err: File::NULL}
  end

  if env = opts[:env]
    env = env.map { |k,v| [k, v.ensure_string] }.to_h
    args.unshift env
  end

  IO.popen(*args, &block)
end

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
  if options[:tail] == true
    params << "+\\>"
    $stderr.puts "Seeking to end of stream..."
  end

  if options[:clear]
    params << "-X"
    params << "-F" unless options[:always] == true
  end

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

def which(bin)
  ENV["PATH"].split(":").find do |path|
    result = File.join(path, bin)
    return result if File.exists? result
  end
  nil
end

def term_width
  require 'io/console'
  STDOUT.winsize.last
end

def concatenate_enumerables(*enums)
  enums = enums.map { |enum| enum.is_a?(String) ? enum.each_line : enum }

  Enumerator.new do |y|
    enums.each do |enum|
      enum.each { |e| y << e }
    end
  end
end

def show_image(filename)
  depends bins: "feh"
  system("feh", filename)
  ""
end

def tmp_filename(prefix="c", length=20)
  chars = [*'a'..'z'] + [*'A'..'Z'] + [*'0'..'9']
  name  = nil
  loop do
    name = "/tmp/#{prefix}-#{length.times.map { chars.sample }.join}"
    break unless File.exists?(name)
  end
  name
end

def shebang_lang(filename)
  if File.read(filename, 256) =~ /\A#!(.+)/
    # Shebang!
    lang = case $1
      when /(bash|zsh|sh|make|expect)/ then :bash
      when /ruby/   then :ruby
      when /perl/   then :ruby
      when /python/ then :python
      when /lua/    then :lua
    end
  end
end

def create_tmpdir(prefix="c-")
  alphabet = [*?a..?z, *?A..?Z, *?0..?9]
  suffix_size = 8
  tmp_root = "/tmp"
  raise "Error: #{tmp_root} doesn't exist" unless File.directory? tmp_root

  loop do
    random_suffix = suffix_size.times.map { alphabet[rand(alphabet.size)] }.join('')
    random_dir = "#{prefix}#{random_suffix}"
    potential = File.join(tmp_root, random_dir)
    if File.exists? potential
      puts "#{potential} exists, trying another..."
    else
      Dir.mkdir(potential)
      return potential
    end
  end
end

def youtube_info(url)
  depends bins: "youtube-dl"
  require 'json'
  JSON.parse(run("youtube-dl", "--dump-json", "--write-auto-sub", url))
end

##############################################################################

def render_source(data, format)
  depends gems: "coderay_bash"
  CodeRay.scan(data, format).term
end

def render_ctags(arg)
  depends bins: "ctags"

  load "#{__dir__}/codetree" unless defined? CTags

  entities = CTags.parse(arg.to_s)
  longest_name_width = entities.map { |e| e.name.size }.max

  Enumerator.new do |y|
    y << "=== CTags Overview: ================="
    y << ""
    entities.each do |e|
      padding_size    = (CTags::Entity::TYPE_LENGTH - e.type_name.to_s.size)
      padding_size    = 0 if padding_size < 0
      padding         = " " * padding_size

      y << (
           "<8>[<#{e.type_color}>#{e.type_name}<8>] " + padding +
           "<15>#{e.name.ljust(longest_name_width)}<8> " +
           "<7>#{e.expr}").colorize
           #"<7>#{CodeRay.scan(e.expr, :c).term}").colorize
    end

    y << ""
    y << "=== Source code: ================="
    y << ""
  end
end

def print_source(arg, lang=nil)
  depends gems: "coderay_bash"

  path = Pathname.new(arg)
  ext = path.extname #filename[/\.[^\.]+$/]
  filename = path.filename

  lang ||= shebang_lang(path) ||
           EXT_HIGHLIGHTERS[ext] ||
           FILENAME_HIGHLIGHTERS[filename]

  output = begin
    if ext == ".json"
      require 'json'
      begin
        data = File.read(arg)
        json = JSON.parse(data)
        CodeRay.scan(JSON.pretty_generate(json), :json).term
      rescue JSON::ParserError
        data
      end
    elsif lang.is_a? Array
      run(*lang, arg)
    elsif lang
      CodeRay.scan_file(path, lang).term
    else
      CodeRay.scan_file(path).term
    end
  rescue ArgumentError
    # Default is to dump file system information about the file and guess its magic type
    concatenate_enumerables run("file", path), run("ls", "-l", path)
  end

  if CTAGS_EXTS.include? ext
    output = concatenate_enumerables render_ctags(path), output
  end

  output
end

##############################################################################
#
# Markdown to ANSI Renderer ("BlackCarpet")
#
# This class takes a little while to initialize, so instead of slowing down the script for every non-markdown file,
# I've wrapped it in a proc which gets lazily loaded by `render_markdown` when needed.
#

BLACKCARPET_INIT = proc do

  begin
    require 'epitools/colored'
    require 'redcarpet'
  rescue LoadError
    return "\e[31m\e[1mNOTE: For colorized Markdown files, 'gem install epitools redcarpet'\e[0m\n\n" \
      + print_source(filename)
  end

  class BlackCarpet < Redcarpet::Render::Base
  private

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

    def smash(s)
      s&.downcase&.scan(/\w+/)&.join
    end

  public
    def normal_text(text)
      text
    end

    def raw_html(html)
      ''
    end


    def link(link, title, content)
      unless content&.[] /^Back /
        str = ""
        str += "<15>#{content}</15>" if content
        if title
          if smash(title) != smash(content)
            str += " <8>(</8><11>#{title}</11><8>)</8>"
          end
        elsif link
          str += " <8>(</8><9>#{link}</9><8>)</8>"
        end

        str.colorize
      end
    end

    def block_code(code, language1=nil)
      language = language1
      language ||= "ruby"

      language = language.split.reject { |chunk| chunk["#compile"] }.first.gsub(/^\./, '')
      # language = language[1..-1] if language[0] == "."  # strip leading "."
      # language = language.scan(/\.?(\w+)/).flatten.first
      language = "cpp"          if language == "C++"
      language = "common-lisp"  if language == "commonlisp"

      require 'coderay'
      if CodeRay::Scanners.list.include? language.to_sym
        "#{indent CodeRay.scan(code, language).term, 4}\n"
      else
        "#{indent render_rouge(code, language), 4}\n"
      end
    end

    def block_quote(text)
      indent paragraph(text)
    end

    def codespan(code)
      code&.cyan
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

    def table_cell(content, alignment)
      @cells ||= []
      @cells << content

      content
    end

    def table_row(content)
      @rows ||= []

      if @cells
        @rows << @cells.dup
        @cells.clear
      else
        @rows << []
      end

      content
    end

    def table(header, body)
      headings = @rows.shift
      table    = Terminal::Table.new(headings: headings, rows: @rows)
      @rows    = []

      "#{table}\n\n"
    end

  end

  BlackCarpet
end


def print_markdown(markdown)
  depends gems: ["redcarpet", "epitools"]

  begin
    require 'epitools/colored'
    require 'redcarpet'
  rescue LoadError
    return "\e[31m\e[1mNOTE: For colorized Markdown files, 'gem install epitools redcarpet'\e[0m\n\n" \
      + markdown
  end

  # Lazily load markdown renderer
  BLACKCARPET_INIT.call unless defined? BlackCarpet

  options = {
    no_intra_emphasis: true,
    fenced_code_blocks: true,
  }

  begin
    require 'terminal-table'
    carpet = Redcarpet::Markdown.new(BlackCarpet, options.merge(tables: true))
  rescue LoadError
    carpet = Redcarpet::Markdown.new(BlackCarpet, options)
  end

  convert_htmlentities carpet.render(markdown)
end

##############################################################################

def print_asciidoc(data)
  depends gems: "asciidoctor"
  IO.popen(["asciidoctor", "-o", "-", "-"], "r+") do |io|
    io.write(data)
    io.close_write
    print_html(io.read)
  end
end

##############################################################################

def print_epub(file)
  depends gems: 'epub-parser'
  require 'epub/parser'
  epub = EPUB::Parser.parse(file)

  Enumerator.new do |out|
    epub.each_page_on_spine do |page|
      out << print_html(page.read)
      out << ""
    end
  end
end

##############################################################################

def moin2markdown(moin)
  convert_tables = proc do |s|
    chunks = s.each_line.chunk { |line| line.match? /^\s*\|\|.*\|\|\s*$/ }

    flattened = chunks.map do |is_table, lines|
      if is_table

        lines.map.with_index do |line,i|
          cols = line.scan(/(?<=\|\|)([^\|]+)(?=\|\|)/).flatten

          newline = cols.join(" | ")
          newline << " |" if cols.size == 1
          newline << "\n"

          if i == 0
            sep = cols.map { |col| "-" * col.size }.join("-|-") + "\n"

            if cols.all? { |col| col.match? /__.+__/ } # table has headers!
              [newline, sep]
            else
              empty_header = (["..."]*cols.size).join(" | ") + "\n"
              [empty_header, sep, newline]
            end
          else
            newline
          end
        end

      else
        lines
      end
    end.flatten

    flattened.join
  end

  markdown = moin.
    gsub(/^(={1,5}) (.+) =+$/) { |m| ("#" * $1.size ) + " " + $2 }. # headers
    gsub(/'''/, "__").                            # bolds
    gsub(/''/, "_").                              # italics
    gsub(/\{\{(?:attachment:)?(.+)\}\}/, "![](\\1)").  # images
    gsub(/\[\[(.+)\|(.+)\]\]/, "[\\2](\\1)").     # links w/ desc
    gsub(/\[\[(.+)\]\]/, "[\\1](\\1)").           # links w/o desc
    gsub(/^#acl .+$/, '').                        # remove ACLs
    gsub(/^<<TableOfContents.+$/, '').            # remove TOCs
    gsub(/^## page was renamed from .+$/, '').    # remove 'page was renamed'
    # TODO: use `html-renderer` to convert it to ANSI
    gsub(/^\{\{\{\n^#!raw\n(.+)\}\}\}$/m, "\\1"). # remove {{{#!raw}}}s
    # TODO: convert {{{\n#!highlight lang}}}s (2-phase: match {{{ }}}'s, then match first line inside)
    gsub(/\{\{\{\n?#!(?:highlight )?(\w+)\n(.+)\n\}\}\}$/m, "```\\1\n\\2\n```"). # convert {{{#!highlight lang }}} to ```lang ```
    gsub(/\{\{\{\n(.+)\n\}\}\}$/m, "```\n\\1\n```")  # convert {{{ }}} to ``` ```

  markdown = convert_tables[markdown]
end

def print_moin(moin)
  print_markdown(moin2markdown(moin))
end

##############################################################################

def wikidump_dir?(path)
  ["*-current.xml", "*-titles.txt"].all? { |pat| path.glob(pat).any? }
end

def print_wikidump(filename)
  require 'nokogiri'
  require 'date'

  doc = Nokogiri::XML(open(filename))

  Enumerator.new do |out|
    doc.search("page").each do |page|
      title = page.at("title").inner_text
      rev = page.at("revision")
      date = DateTime.parse(rev.at("timestamp").inner_text).strftime("%Y-%m-%d")
      body = rev.at("text").inner_text

      # out << "<8>=== <15>#{title} <7>(<11>#{date}<7>) <8>=========================".colorize
      out << "\e[30m\e[1m=== \e[0m\e[37m\e[1m#{title} \e[0m\e[37m(\e[0m\e[36m\e[1m#{date}\e[0m\e[37m) \e[0m\e[30m\e[1m=========================\e[0m"
      out << ""
      out << body
      # parsed_page = WikiCloth::Parser.new(params: { "PAGENAME" => title }, data: body)
      # out << parsed_page.to_html
      out << ""
      out << ""
    end
  end
end

##############################################################################

def print_bookmarks(filename)
  require 'nokogiri'

  doc = Nokogiri::HTML(open(filename))

  Enumerator.new do |out|
    doc.search("a").each do |a|
      out << "\e[1;36m#{a.inner_text}\e[0m"
      out << "  #{a["href"]}"
      out << ""
    end
  end
end

##############################################################################

def print_rst(filename)
  depends(bins: "rst2ansi")
  result = run("rst2ansi", filename, noerr: true)
  if $?&.success?
    result
  else
    run("rst2ansi", filename)
  end
end

##############################################################################

def print_orgmode(input)
  markdown = render_pandoc(input, "org", "markdown")
  print_markdown markdown
end

##############################################################################

def print_doc(filename)
  out = tmp_filename
  if which("wvText")
    system("wvText", filename, out)
    result = File.read out
    File.unlink out
    result
  elsif which("catdoc")
    run "catdoc", filename
  else
    "\e[31m\e[1mError: Coudln't find a .doc reader; install 'wv' or 'catdoc'\e[0m"
  end
end

##############################################################################

def print_rtf(filename)
  if which("catdoc")
    width = term_width - 5
    run "catdoc", "-m", width.to_s, filename
  else
    "\e[31m\e[1mError: Coudln't find an .rtf reader; install 'catdoc'\e[0m"
  end
end

##############################################################################

def print_srt(filename)
  return to_enum(:print_srt, filename) unless block_given?

  last_time = 0

  enum = Pathname.new(filename).each

  loop do
    n     = enum.next
    times = enum.next
    a, b  = times.split(" --> ").map { |s| s.gsub(",", ".").from_hms }
    gap   = -last_time + a

    yield "" if gap > 1
    yield "" if gap > 6
    yield "" if gap > 40
    yield "------------------\n\n" if gap > 100

    loop do
      line = enum.next
      break if line.empty?
      yield line.gsub(/<\/?[^>]+>/, "")
    end

    last_time = b
  end
end

def print_vtt(filename)
  return to_enum(:print_vtt, filename) unless block_given?

  grey = "\e[1;30m"
  white = "\e[0m"

  strip_colors = proc do |line|
    line.gsub(%r{<[^>]+>}i, '').strip
  end

  last_time = 0
  enum = Pathname.new(filename).each

  enum.take_while { |line| line[/^(\#\#|WEBVTT)$/] }
  enum.take_while { |line| line.strip == "" }

  prev = nil

  loop do
    times             = enum.next
    a, b              = times.split.values_at(0,2) #.map(&:from_hms)
    printed_timestamp = false

    loop do
      break if (line = enum.next).empty?

      stripped = convert_htmlentities( strip_colors[line] )

      unless stripped.empty? or stripped == prev
        unless printed_timestamp
          yield "#{grey}#{a} #{white}#{stripped}"
          printed_timestamp = true
        else
          yield "#{grey}#{" " * (a ? a.size : 0)} #{white}#{stripped}"
        end

        prev = stripped
      end
    end

  end
end

##############################################################################

def print_iso(filename)
  run("lsiso", filename, stderr: true)
end

##############################################################################

def print_ipynb(filename)
  require 'json'

  json = JSON.load(open(filename))
  output = []

  json["cells"].each do |c|
    case c["cell_type"]
    when "markdown"
      output << "#{c["source"].join}\n\n"
    when "code"
      # FIXME: Hardwired to python; check if a cell's metadata attribute supports other languages
      output << "\n```python\n#{c["source"].join}\n```\n\n"
    else
      raise "unknown cell type: #{c["cell_type"]}"
    end
  end

  print_markdown(output.join)
end

##############################################################################

def print_torrent(filename)
  require 'bencode'
  require 'digest/sha1'

  data = BEncode.load_file(filename)

  date        = data["creation date"] && Time.at(data["creation date"])
  name        = data.dig "info", "name"
  infohash    = Digest::SHA1.hexdigest(BEncode.dump data["info"])
  files       = data["info"]["files"]
  trackers    = [data["announce"], *data["announce-list"]].compact
  urls        = data["url-list"]
  col1_size   = files.map { |f| f["length"] }.max.to_s.size if files
  comment     = data["comment"]
  creator     = data["created by"]
  piece_size  = data.dig "info", "piece length"
  pieces      = data.dig("info", "pieces").size / 20
  total_size  = data.dig("info", "length") || files && files.map { |f| f["length"] }.reduce(:+)

  output = []

  output << "Name:        #{name}" if name
  output << "Created At:  #{date}" if date
  output << "Infohash:    #{infohash}"
  output << "Comment:     #{comment}" if comment
  output << "Created By:  #{creator}" if creator
  output << "Pieces:      #{pieces.commatize} @ #{piece_size.commatize} bytes = ~#{(pieces * piece_size).commatize} bytes"
  output << "Total Size:  #{total_size.commatize}"
  output << ""

  if files
    files.sort_by { |f| [-f["path"].size, f["path"]] }.each do |f|
      output << "#{f["length"].to_s.rjust(col1_size)} | #{f["path"].join("/")}"
    end
    output << ""
  end

  {
    "Trackers:" => trackers,
    "URLs:"     => urls
  }.each do |title, things|
    if things
      output << "----------------"
      output << title
      output << "----------------"
      things.each {|t| output << t }
      output << ""
    end
  end

  # data["info"]["pieces"] = "[...#{data["info"]["pieces"].size} bytes of binary data...]"
  output.join("\n")
end

##############################################################################

def print_ffprobe(arg)
  result = run("ffprobe", "-hide_banner", arg, stderr: true)
  highlight_lines_with_colons(result)
end

##############################################################################

def print_exif(arg)
  run("exiv2", "pr", arg, stderr: true)
end

##############################################################################

def print_cp437(filename)
  open(filename, "r:cp437:utf-8", &:read).gsub("\r", "")
end

##############################################################################

def print_obj(filename)
  highlight_lines_with_colons(run("objdump", "-xT", filename))
end

##############################################################################

# def print_sqlite(filename)
#   stats  = run("sqlite3", filename, ".dbinfo").read
#   schema = run("sqlite3", filename, ".schema --indent").read

#   print_header("Statistics:",1) +
#     stats + "\n" +
#   print_header("Schema:",2) +
#     CodeRay.scan(schema, :sql).term
# end

def print_sqlite(filename)
  return to_enum(:print_sqlite, filename) unless block_given?
  depends gems: ["sequel", "sqlite3"]

  require 'sequel'
  require 'pp'

  Sequel.sqlite(filename) do |db|
    db.tables.each do |table|
      yield print_header("#{table}", 1)
      schemas = db[:sqlite_master].where(tbl_name: "#{table}").select(:sql).map(&:values).flatten.join("\n")
      yield CodeRay.scan(schemas, :sql).term
      yield ""
      begin
        db[table].each { |row| yield CodeRay.scan(row.pretty_inspect, :ruby).term }
      rescue Sequel::DatabaseError => e
        yield e.inspect
      end
      yield ""
      yield ""
    end
  end
end

##############################################################################

def leveldb_dir?(path)
  # Example leveldb dir:
  #   000005.ldb  000007.ldb  000008.log  CURRENT  LOCK  LOG  LOG.old  MANIFEST-000006
  path/"CURRENT" and path/"LOG" and path.glob("*.ldb").any?
end

def print_leveldb(path)
  depends gem: "leveldb"

  require 'leveldb'
  require 'epitools/colored'

  db = LevelDB::DB.new(path.to_s)

  Enumerator.new do |y|
    y << "<8>=== <15>LevelDB Stats: <8>==================================".colorize
    y << ""
    y << db.stats
    y << ""
    y << ""
    y << "<8>=== <15>Database Contents:<8>==================================".colorize
    y << ""
    db.each do |key, val|
      y << key.inspect.light_cyan # CodeRay::Encoders::Terminal::TOKEN_COLORS[:method]
      y << "  #{val.inspect}"
    end
  end
end

##############################################################################

def print_ssl_certificate(filename)
  depends bins: "openssl"

  #IO.popen(["openssl", "x509", "-in", filename, "-noout", "-text"], "r")
  result = nil
  %w[pem der net].each do |cert_format|
    result = run("openssl", "x509",
        "-fingerprint", "-text", "-noout",
        "-inform", cert_format,
        "-in", filename,
        stderr: true)

    break unless result =~ /unable to load certificate/
  end

  highlight_lines_with_colons(result)
end

##############################################################################

def print_gpg(filename)
  depends bins: "gpg"

  run("gpg", "--list-packets", "-v", filename)
end

##############################################################################

def print_pickle(filename)
  depends bins: "python"
  run("python", "-c", "import pickle; print(repr(pickle.load(open('#{filename}', 'rb'))))", filename)
end

##############################################################################

def print_csv(filename)
  require 'csv'

  plain     = "\e[0m"
  grey      = "\e[30;1m"
  red       = "\e[31;1m"
  cyan      = "\e[36;1m"
  dark_cyan = "\e[36m"

  if filename[/\.xls$/]
    io = IO.popen(["xls2csv", filename], "rb")
    csv = CSV.new(io) #, row_sep: "\r\n")
  else
    tabs, commas = open(filename, "rb") { |f| f.each_line.take(5) }.map(&:chomp).map { |l| l.scan(%r{(,|\t)})}.flatten.partition { |e| e == "\t" }
    separator = tabs.size > commas.size ? "\t" : ","
    csv = CSV.open(filename, "rb", col_sep: separator)
  end

  numbered_rows = csv.map.with_index do |row, n|
    clean_row = row.map { |cell| cell && cell.strip }
    [n.to_s, *clean_row]
  end

  col_maxes = numbered_rows.map { |row| row.map { |cell| cell && cell.size } }.
    transpose_with_padding.
    map {|col| col.compact.max.to_i }

  header    = numbered_rows.shift
  header[0] = ""
  sep       = grey + col_maxes.map { |max| "-" * max }.join("-|-") + plain

  render_row = proc do |row, textcolor|
    cells = row.zip(col_maxes).map.with_index do |(col, max), i|
      padded = (col || "nil").ljust(max)

      color = if i == 0
                dark_cyan
              elsif col
                textcolor
              else
                red
              end

      "#{color}#{padded}"
    end

    cells.join("#{grey} | ")
  end

  [
    render_row.call(header, cyan),
    sep,
    *numbered_rows.map { |therow| render_row.call(therow, plain) }
  ].join("\n")
end

##############################################################################
# TODO: wide view improvement: put ascii chars side by each, but stack hex digits topwise
def print_hex(arg, side_by_side=true)
  depends gems: "epitools"
  require 'epitools/colored'
  require 'io/console'

  height, width = $stdout.winsize

  ##################################################################################
  #
  # Constants in the calculation of bytes_per_line:
  #   3 chars per hex byte
  #   8 chars for the offset
  #   6 chars total for padding
  #   2 chars for margins
  #   (the rest is the bytes_per_line)
  #
  bytes_per_line = side_by_side ? (width - 16) / 4 : (width - 9) / 2
                                 # ^^^^^^^^^^^^^^^ Derived from: bytes_per_line = Term.width - 3*bytes_per_line - 8 - 6 - 2
  empty_line     = ["\0"] * bytes_per_line
  skip_begins_at = nil

  # Highlight spans of a certain size
  sector_size = nil
    # if opts[:sectors]
    #   512
    # elsif opts[:chunks]
    #   opts[:chunks].to_i
    # else
    #   nil
    # end

  highlight_colors = {
    hex:  [7, 15],
    text: [3, 11]
  }

  #
  highlight = proc do |type, chars, offset|
    colors               = highlight_colors[type]
    sector_num, underlap = offset.divmod(sector_size)
    overlap              = sector_size - underlap

    chunks = []

    if underlap >= 0
      color = colors[sector_num % 2]
      chunks << [ "<#{color}>", chars[0...overlap] ]
    end

    (overlap..chars.size).step(sector_size).with_index do |chunk_offset, index|
      color = colors[(sector_num + index + 1) % 2]
      chunks << [ "<#{color}>", chars[chunk_offset...chunk_offset+sector_size] ]
    end

    chunks.flatten
  end

  # #
  # # Super awesome `highlight` test
  # #
  # sector_size = 4
  # 1000.times do  |offset|
  #   print "\e[2J"
  #   puts highlight.(:hex, "highlight.the.shit.out.of.me", offset)
  #   sleep 0.1
  # end
  # exit

  ##################################################################################

  Enumerator.new do |output|

    ###
    classic_print_line = proc do |chars, line|
      offset = bytes_per_line * line

      # Skip nulls
      if chars == empty_line
        skip_begins_at = offset unless skip_begins_at
        next
      end

      if skip_begins_at
        skip_length = offset - skip_begins_at
        output << "         <8>[ <4>skipped <12>#{skip_length.commatize} <4>bytes of NULLs <8>(<12>#{skip_begins_at.commatize}<4> to <12>#{offset.commatize}<8>) <8>] ".colorize
        skip_begins_at = nil
      end

      hex = chars.map { |b| "%0.2x " % b.ord }
      underflow = bytes_per_line - hex.size
      hex += ['   ']*underflow if underflow > 0

      # Offset
      a = "<3>%0.8x</3>" % offset

      # Hex
      b = sector_size ? highlight.(:hex, hex, offset) :  hex

      # Chars
      c = sector_size ? highlight.(:text, chars, offset) : chars

      # Replace unprintable characters
      c = c.map do |c|
        case c.ord
        when 32..126
          c
        when 0
          "<8>_</8>"
        else
          "<8>.</8>"
        end
      end

      output << "#{a} #{b.join} <8>|<7>#{c.join}</7><8>|".colorize
    end

    ###
    interleaved_print_line = proc do |chars, line|
      offset = bytes_per_line * line

      # Skip nulls
      if chars == empty_line
        skip_begins_at = offset unless skip_begins_at
        next
      end

      if skip_begins_at
        skip_length = offset - skip_begins_at
        output << "         <8>[ <4>skipped <12>#{skip_length.commatize} <4>bytes of NULLs <8>(<12>#{skip_begins_at.commatize}<4> to <12>#{offset.commatize}<8>) <8>] ".colorize
        skip_begins_at = nil
      end

      hex = chars.map.with_index { |b, i| "<#{(i%2==0) ? 2 : 3}>%0.2x" % b.ord }
      #underflow = bytes_per_line - hex.size
      #hex += ['   ']*underflow if underflow > 0

      # Offset
      a = "<3>%0.8x</3>" % offset

      # Hex
      b = sector_size ? highlight.(:hex, hex, offset) :  hex

      # Chars
      c = sector_size ? highlight.(:text, chars, offset) : chars

      # Replace unprintable characters
      c = c.map do |c|
        case c.ord
        when 32..126
          c
        when 0
          "<8>_</8>"
        else
          "<8>.</8>"
        end
      end

      output << "#{a} #{b.join}".colorize
      output << "         <7>#{c.join(" ")}</7>".colorize
    end

    skip_begins_at = nil

    print_line = side_by_side ? classic_print_line : interleaved_print_line

    open(arg, "rb") do |io|
      io.each_char.each_slice(bytes_per_line).with_index(&print_line)
    end

  end # Enumerator
end

##############################################################################

# def pretty_xml(data)
#   require "rexml/document"

#   result    = ""
#   doc       = REXML::Document.new(data)
#   formatter = REXML::Formatters::Pretty.new

#   formatter.compact = true # use as little whitespace as possible
#   formatter.write(doc, result)

#   result
# end

##############################################################################

def print_archive(filename)
  header = Enumerator.new do |out|
    out << "Contents of: #{filename}"
  end

  header + (
    case filename
    when /\.tar\.zst$/
      depends bins: "zstd"
      run("tar", "-Izstd", "-tvf", filename)
    else
      depends bins: "atool"
      run("atool", "-l", filename)
    end
  )
end

def print_zip(filename)
  depends bins: "unzip"

  run("unzip", "-v", filename)
end

def print_archived_xml_file(archive, internal_file)
  depends gems: "coderay"
  # internal_ext = File.extname(internal_file)
  case archive.extname
  when ".k3b"
    data = IO.popen(["unzip", "-p", archive.to_s, internal_file]) { |io| io.read }
    CodeRay.scan(pretty_xml(data), :xml).term
  end
end

##############################################################################

def print_xpi_info(filename)
  depends bins: "atool"

  require 'json'
  manifest = run("atool", "-c", filename, "manifest.json")
  h        = JSON.parse(manifest)
  perms    = h["permissions"]
  matches  = h["content_scripts"]&.map { |cs| cs["matches"] }&.flatten&.uniq

  result = []
  result << "#"*40
  result << "   #{h["name"]} v#{h["version"]}"
  result << "#"*40
  result << ""
  result << "Permissions: #{perms.join(", ")}"                if perms
  result << "URLs matched: #{matches.join(", ")}"   if matches
  result << run("atool", "-l", filename)
  result << ""

  result
end

##############################################################################
# Pretty-print XML

def nice_xml(xml)
  require "rexml/document"

  doc       = REXML::Document.new(xml)
  formatter = REXML::Formatters::Pretty.new

  formatter.compact = true # use as little whitespace as possible

  result = ""
  formatter.write(doc, result)

  result
end

##############################################################################

def print_xml(filename)
  header = open(filename, "rb") { |f| f.each_byte.take(4) }

  if header == [3, 0, 8, 0]
    # Android binary XML
    depends bins: "axmlprinter"
    xml = IO.popen(["axmlprinter", filename], &:read)
    convert_htmlentities(CodeRay.scan(nice_xml(xml), :xml).term)
  else
    # Regular XML
    convert_htmlentities( print_source( nice_xml( File.read(filename) ), :xml) )
  end
end

##############################################################################

def print_bibtex(filename)
  depends gems: ["bibtex", "epitools"]

  require 'bibtex'
  require 'epitools/colored'

  out = StringIO.new
  bib = BibTeX.open(filename)

  bib.sort_by { |entry| entry.fields[:year] || "zzzz" }.each do |entry|
    o      = OpenStruct.new entry.fields
    year   = o.year ? o.year.to_s : "____"
    indent = " " * (year.size + 1)

    out.puts "<14>#{year} <15>#{o.title} <8>(<7>#{entry.type}<8>)".colorize

    out.puts "#{indent}<11>#{o.author}".colorize if o.author

    out.puts "#{indent}#{o.booktitle}"    if o.booktitle
    out.puts "#{indent}#{o.series}"       if o.series
    out.puts "#{indent}#{o.publisher}"    if o.publisher
    out.puts "#{indent}#{o.journal}, Vol. #{o.volume}, No. #{o.number}, pages #{o.pages}"  if o.journal
    out.puts "#{indent}<9>#{o.url}".colorize if o.url
    out.puts
    # out.puts o.inspect
    # out.puts
  end

  out.seek 0
  out.read
end

def print_http(url)
  require 'pp'
  require 'uri'
  uri = URI.parse(url)

  if which("youtube-dl") and uri.host =~ /(youtube\.com|youtu\.be)$/
    depends gems: "coderay"
    # TODO: Pretty-print video title/description/date/etc, and render subtitles (if available)
    json = youtube_info(url)
    CodeRay.scan(JSON.pretty_generate(json), :json).term
  else
    # IO.popen(["lynx", "-dump", url]) { |io| io.read }
    require 'open-uri'
    html = URI.open(url, &:read)
    print_html(html)
  end
end

##############################################################################

def print_html(html)
  depends gems: "html-renderer"
#  unless defined? HTMLRenderer
#    gem 'html-renderer', '>= 0.1.2'
    require 'html-renderer/ansi'
#  end
  HTMLRenderer::ANSI.render(html)
end

##############################################################################

def print_weechat_log(filename)
  depends gems: 'epitools'
  require 'epitools/colored'

  line_struct = Struct.new(:date, :time, :nick, :msg)
  colors      = [2,3,4,5,6,9,10,11,12,13,14,15]
  last_date   = nil
  slice_size  = 100

  Enumerator.new do |out|
    open(filename).each_line.each_slice(slice_size) do |slice|

      lines        = slice.map { |line| line_struct.new *line.chomp.split(/\s+/, 4) }
      longest_nick = lines.map { |l| l.nick.size }.max

      lines.each do |l|
        if l.date != last_date
          out << ""
          out << "<8>==== <11>#{l.date} <8>=============================".colorize
          out << ""
          last_date = l.date
        end

        case l.nick
        when "--"
          out << "<8>-- #{l.msg}".colorize
        when "<--", "-->"
          out << "<8>#{l.nick} #{l.msg}".colorize
        else
          color         = colors[l.nick.chars.map(&:ord).sum % colors.size]
          indented_nick = l.nick.rjust(longest_nick)
          out << "<8>[#{l.time}] <#{color}>#{indented_nick}  <7>#{l.msg}".colorize
        end
      end

    end
  end
end

##############################################################################

def print_pdf(file)
  depends bins: "pdftohtml"

  raise "Error: 'pdftohtml' is required; install the 'poppler' package" unless which("pdftohtml")
  raise "Error: 'html2ansi' is required; install the 'html-renderer' gem" unless which("html2ansi")

  html = run("pdftohtml", "-stdout", "-noframes", "-i", file)
  print_html(html)
end

##############################################################################

def highlight(enum, &block)
  enum = enum.each_line if enum.is_a? String
  Enumerator.new do |y|
    enum.each do |line|
      y << block.call(line)
    end
  end
end

def highlight_lines_with_colons(enum)
  highlight(enum) do |line|
    if line =~ /^(\s*)(\S+):(.*)/
      "#{$1}\e[37;1m#{$2}\e[0m: #{$3}"
    else
      line
    end
  end
end

##############################################################################

DECOMPRESSORS = {
  ".gz"  => %w[gzip -d -c],
  ".xz"  => %w[xz -d -c],
  ".bz2" => %w[bzip2 -d -c],
  ".zst" => %w[zstd -d -c],
}

def convert(arg)

  arg = arg.sub(%r{^file://}, '')

  if arg =~ %r{^https?://.+}
    print_http(arg)
  else
    arg = which(arg) unless File.exists? arg

    raise Errno::ENOENT unless arg

    path = Pathname.new(arg)

    #
    # If it's a directory, show the README, or print an error message.
    #
    if path.directory?
      if leveldb_dir?(path)
        return print_leveldb(path)
      elsif wikidump_dir?(path)
        print_wikidump(path.glob("*-current.xml").first)
      else
        readmes = Dir.foreach(arg).select { |f| File.file?(f) and (f[/(^readme|^home\.md$|\.gemspec$|^cargo.toml$|^pkgbuild$|^default.nix$)/i]) }.sort_by(&:size)
        if readme = readmes.first
          return convert("#{arg}/#{readme}")
        else
          return run("tree", arg)
          # return "\e[31m\e[1mThat's a directory!\e[0m"
        end
      end
    end


    # TODO: Fix relative symlinks
    # arg = File.readlink(arg) if File.symlink?(arg)

    #### MEGA SWITCH STATEMENT ####
    ext = path.extname.downcase

    if path.filename =~ /\.tar\.(gz|xz|bz2|lz|lzma|pxz|pixz|lrz|zst)$/ or
       ext =~ /\.(tgz|tar|zip|rar|arj|lzh|deb|rpm|7z|apk|pk3|jar|gem|iso|wim)$/
      print_archive(arg)
    elsif cmd = DECOMPRESSORS[ext]
      run(*cmd, arg)
    elsif path.filename =~ /.+-current\.xml$/
      print_wikidump(arg)
    elsif path.filename =~ /bookmark.+\.html$/i
      print_bookmarks(arg)
    elsif path.filename =~ /^id_(rsa|ed25519|dsa|ecdsa)(\.pub)?$/
      print_ssl_certificate(arg)
    else
      case ext
      when *%w[.html .htm]
        print_html(File.read arg)
      when *%w[.md .markdown .mdwn .page]
        print_markdown(File.read arg)
      when *%w[.moin .wiki]
        print_moin(File.read arg)
      when *%w[.adoc]
        print_asciidoc(File.read arg)
      when *%w[.epub]
        print_epub(arg)
      when *%w[.ipynb]
        print_ipynb(arg)
      when /^\.[1-9]$/ # manpages
        run("man", "-l", "-Tascii", arg, env: {"MANWIDTH" => term_width})
      when *%w[.torrent]
        print_torrent(arg)
      when *%w[.nfo .ans .drk .ice]
        print_cp437(arg)
      when *%w[.rst]
        print_rst(arg)
      when *%w[.org]
        print_orgmode(path)
      when *%w[.srt]
        print_srt(arg)
      when *%w[.vtt]
        print_vtt(arg)
      # when *%w[.iso]
      #   print_iso(arg)
      when *%w[.pdf]
        print_pdf(arg)
      when *%w[.doc .docx]
        print_doc(arg)
      when *%w[.rtf]
        print_rtf(arg)
      when *%w[.pem .crt]
        print_ssl_certificate(arg)
      when *%w[.sig .asc]
        print_gpg(arg)
      when *%w[.pickle]
        print_pickle(arg)
      when *%w[.xml]
        print_xml(arg)
      when *%w[.csv .xls]
        print_csv(arg)
      when *%w[.weechatlog]
        print_weechat_log(arg)
      when *%w[.mp3 .mp2 .ogg .webm .mkv .mp4 .m4a .m4s .avi .mov .qt .rm .wma .wmv]
        print_ffprobe(arg)
      when *%w[.jpg .jpeg]
        print_exif(arg)
      when ".tsv"
        print_csv(arg)
        # print_csv(arg, "\t") # it autodetects now. (kept for posterity)
      when ".bib"
        print_bibtex(arg)
      when ".xpi"
        print_xpi_info(arg)
      when ".k3b"
        print_archived_xml_file(path, "maindata.xml")
      else
        format = run('file', arg).to_a.join

        case format
        when /SQLite 3.x database/
          print_sqlite(arg)
        when /Zip archive/
          print_zip(arg)
        when /shell script/
          print_source(arg)
        when /:.+?(ELF|(?<!text )executable|shared object)[^,]*,/
          print_obj(arg)
        when /(image,|image data)/
          show_image(arg)
        when /: data$/
          print_hex(arg)
        else
          print_source(arg)
        end
      end
    end
  end

end


### MAIN #####################################################################

if $0 == __FILE__

  args = ARGV

  if args.size == 0 or %w[--help].include? args.first
    puts "usage: c [options] <filename(s)>"
    puts
    puts "options:"
    puts "      -s   Always scrollable (don't exit if less than a screenfull of text)"
    puts "      -i   Auto-indent file"
    puts "      -h   Side-by-side hex mode (classic)"
    puts "      -x   Interleaved hex mode (characters below hex values)"
    puts

  else # 1 or more args

    wrap                 = !args.any? { |arg| arg[/\.csv$/i] }
    scrollable           = args.delete("-s")
    indent               = args.delete("-i")
    side_by_side_hexmode = args.delete("-h")
    interleaved_hexmode  = args.delete("-x")

    lesspipe(:wrap=>wrap, :clear=>!scrollable) do |less|

      args.each do |arg|
        begin
          if args.size > 1
            less.puts "\e[30m\e[1m=== \e[0m\e[36m\e[1m#{arg} \e[0m\e[30m\e[1m==============\e[0m"
            less.puts
          end

          begin
            # TODO: this breaks if you pass a dir; move this inside `convert(arg)`
            result = if side_by_side_hexmode
              print_hex(arg)
            elsif interleaved_hexmode
              print_hex(arg, false)
            else
              convert(arg)
            end
          rescue Errno::EACCES
            less.puts "\e[31m\e[1mNo read permission for \e[0m\e[33m\e[1m#{arg}\e[0m"
            # less.puts "\e[31m\e[1mNo read permission for \e[0m\e[33m\e[1m#{arg}\e[0m"
            next
          rescue Errno::ENOENT => e
            # less.puts "\e[31m\e[1mFile not found.\e[0m"
            less.puts "\e[31m\e[1m#{e}\e[0m"
            next
          end

          case result
          when Enumerable
            result.each { |line| less.puts line }
          when String
            result.each_line { |line| less.puts line }
          end

          less.puts
          less.puts

        end # each arg
      rescue MissingDependency => e
        less.puts e.to_s
      end
    end # lesspipe

  end

end
