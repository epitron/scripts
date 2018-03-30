#!/usr/bin/env ruby
##############################################################################
#
# SuperCat! Print every file format, in beautiful ansi colour!
#
# Optional dependencies:
#
#   ruby gems:
#     redcloth (for markdown)
#     nokogiri (for wikidumps)
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
#   * Change `print_*` methods to receive a string (raw data) or a Pathname/File object
#   *
#   * "c directory/" should print "=== directory/README.md ========" in the filename which is displayed in multi-file mode
#   * Print [eof] between files when in multi-file mode
#   * Make .ANS files work in 'less' (less -S -R, cp437)
#   * Refactor into "filters" and "renderers", with one core loop to dispatch
#     (eg: special rules for when a shebang starts the file)
#
##############################################################################
require 'pathname'
require 'coderay'
require 'coderay_bash'
##############################################################################

THEMES = {
  siberia:   {:class=>"\e[34;1m", :class_variable=>"\e[34;1m", :comment=>"\e[33m", :constant=>"\e[34;1m", :error=>"\e[37;44m", :float=>"\e[33;1m", :global_variable=>"\e[33;1m", :inline_delimiter=>"\e[32m", :instance_variable=>"\e[34;1m", :integer=>"\e[33;1m", :keyword=>"\e[36m", :method=>"\e[36;1m", :predefined_constant=>"\e[36;1m", :symbol=>"\e[36m", :regexp=>{:modifier=>"\e[36m", :self=>"\e[34;1m", :char=>"\e[36;1m", :content=>"\e[34;1m", :delimiter=>"\e[34m", :escape=>"\e[36m"}, :shell=>{:self=>"\e[34;1m", :char=>"\e[36;1m", :content=>"\e[34;1m", :delimiter=>"\e[36m", :escape=>"\e[36m"}, :string=>{:self=>"\e[34;1m", :char=>"\e[36;1m", :content=>"\e[34;1m", :delimiter=>"\e[36m", :escape=>"\e[36m"}},
  ocean:     {:class=>"\e[38;5;11m", :class_variable=>"\e[38;5;131m", :comment=>"\e[38;5;8m", :constant=>"\e[38;5;11m", :error=>"\e[38;5;0;48;5;131m", :float=>"\e[38;5;173m", :global_variable=>"\e[38;5;131m", :inline_delimiter=>"\e[38;5;137m", :instance_variable=>"\e[38;5;131m", :integer=>"\e[38;5;173m", :keyword=>"\e[38;5;139m", :method=>"\e[38;5;4m", :predefined_constant=>"\e[38;5;131m", :symbol=>"\e[38;5;10m", :regexp=>{:modifier=>"\e[38;5;10m", :self=>"\e[38;5;10m", :char=>"\e[38;5;152m", :content=>"\e[38;5;152m", :delimiter=>"\e[38;5;10m", :escape=>"\e[38;5;137m"}, :shell=>{:self=>"\e[38;5;10m", :char=>"\e[38;5;152m", :content=>"\e[38;5;10m", :delimiter=>"\e[38;5;10m", :escape=>"\e[38;5;137m"}, :string=>{:self=>"\e[38;5;10m", :char=>"\e[38;5;152m", :content=>"\e[38;5;10m", :delimiter=>"\e[38;5;10m", :escape=>"\e[38;5;137m"}},
  modern:    {:class=>"\e[38;5;207;1m", :class_variable=>"\e[38;5;80m", :comment=>"\e[38;5;24m", :constant=>"\e[38;5;32;1;4m", :error=>"\e[38;5;31m", :float=>"\e[38;5;204;1m", :global_variable=>"\e[38;5;220m", :inline_delimiter=>"\e[38;5;41;1m", :instance_variable=>"\e[38;5;80m", :integer=>"\e[38;5;37;1m", :keyword=>"\e[38;5;167;1m", :method=>"\e[38;5;70;1m", :predefined_constant=>"\e[38;5;14;1m", :symbol=>"\e[38;5;83;1m", :regexp=>{:modifier=>"\e[38;5;204;1m", :self=>"\e[38;5;208m", :char=>"\e[38;5;208m", :content=>"\e[38;5;213m", :delimiter=>"\e[38;5;208;1m", :escape=>"\e[38;5;41;1m"}, :shell=>{:self=>"\e[38;5;70m", :char=>"\e[38;5;70m", :content=>"\e[38;5;70m", :delimiter=>"\e[38;5;15m", :escape=>"\e[38;5;41;1m"}, :string=>{:self=>"\e[38;5;41m", :char=>"\e[38;5;41m", :content=>"\e[38;5;41m", :delimiter=>"\e[38;5;41;1m", :escape=>"\e[38;5;41;1m"}},
  solarized: {:class=>"\e[38;5;136m", :class_variable=>"\e[38;5;33m", :comment=>"\e[38;5;240m", :constant=>"\e[38;5;136m", :error=>"\e[38;5;254m", :float=>"\e[38;5;37m", :global_variable=>"\e[38;5;33m", :inline_delimiter=>"\e[38;5;160m", :instance_variable=>"\e[38;5;33m", :integer=>"\e[38;5;37m", :keyword=>"\e[38;5;246;1m", :method=>"\e[38;5;33m", :predefined_constant=>"\e[38;5;33m", :symbol=>"\e[38;5;37m", :regexp=>{:modifier=>"\e[38;5;160m", :self=>"\e[38;5;64m", :char=>"\e[38;5;160m", :content=>"\e[38;5;64m", :delimiter=>"\e[38;5;160m", :escape=>"\e[38;5;160m"}, :shell=>{:self=>"\e[38;5;160m", :char=>"\e[38;5;160m", :content=>"\e[38;5;37m", :delimiter=>"\e[38;5;160m", :escape=>"\e[38;5;160m"}, :string=>{:self=>"\e[38;5;160m", :char=>"\e[38;5;160m", :content=>"\e[38;5;37m", :delimiter=>"\e[38;5;160m", :escape=>"\e[38;5;37m"}},
}
CodeRay::Encoders::Terminal::TOKEN_COLORS.merge!(THEMES[:siberia])

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
  '&#8212;' => '--',
  '&#39;'   => "'",
  '&#8217;' => "'",
}

##############################################################################

class Pathname

  def filename
    basename.to_s
  end
  alias_method :name, :filename

end

##############################################################################

class Numeric

  def commatize(char=",")
    int, frac = to_s.split(".")
    int = int.gsub /(\d)(?=\d{3}+(?:\.|$))(\d{3}\..*)?/, "\\1#{char}\\2"

    frac ? "#{int}.#{frac}" : int
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

def run(*args)
  opts = (args.last.is_a? Hash) ? args.last : {}

  if opts[:stderr]
    args << {err: [:child, :out]}
  end

  IO.popen(args)
end

##############################################################################

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

##############################################################################

def which(bin)
  ENV["PATH"].split(":").find do |path|
    result = File.join(path, bin)
    return result if File.exists? result
  end
  nil
end

##############################################################################

def concatenate_enumerables(*enums)
  Enumerator.new do |y|
    enums.each do |enum|
      enum.each { |e| y << e }
    end
  end
end

##############################################################################

def show_image(filename)
  system("feh", filename)
  ""
end

### Converters ###############################################################

CODERAY_EXT_MAPPING = {
  ".cr"          => :ruby,
  ".jl"          => :ruby,
  ".pl"          => :ruby,
  ".cmake"       => :ruby,
  ".mk"          => :bash,
  ".install"     => :bash,
  ".desktop"     => :bash,
  ".conf"        => :bash,
  ".prf"         => :bash,
  ".hs"          => :text,
  ".ini"         => :bash,
  ".service"     => :bash,
  ".cl"          => :c,
  ".gradle"      => :groovy,
  ".sage"        => :python,
  ".lisp"        => :clojure,
  ".scm"         => :clojure,
  ".qml"         => :php,
  ".pro"         => :sql,
  ".ws"          => :xml,
  ".ui"          => :xml,
  ".opml"        => :xml,
  ".nim"         => :pygmentize,
  ".stp"         => :javascript, # systemtap
}

CODERAY_FILENAME_MAPPING = {
  "Rakefile"     => :ruby,
  "Gemfile"      => :ruby,
  "Makefile"     => :bash,
  "makefile"     => :bash,
  "PKGBUILD"     => :bash,
  "configure.in" => :bash,
  "configure"    => :bash,
  "Gemfile.lock" => :c,
  "database.yml" => :yaml,
}


##############################################################################

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

##############################################################################

def print_source(arg)
  path = Pathname.new(arg)
  ext = path.extname #filename[/\.[^\.]+$/]
  filename = path.filename

  lang =  shebang_lang(path) ||
          CODERAY_EXT_MAPPING[ext] ||
          CODERAY_FILENAME_MAPPING[filename]

  if ext == ".json"
    require 'json'
    begin
      data = File.read(filename)
      json = JSON.parse(data)
      CodeRay.scan(JSON.pretty_generate(json), :json).term
    rescue JSON::ParserError
      data
    end
  elsif lang == :pygmentize
    run("pygmentize", path)
  elsif lang
    CodeRay.scan_file(path, lang).term
  else
    CodeRay.scan_file(path).term
  end

rescue ArgumentError
  concatenate_enumerables run("file", path), run("ls", "-l", path)
end

##############################################################################
#
# Markdown to ANSI Renderer ("BlackCarpet")
#
# This class takes a little while to initialize, so instead of slowing down the script for every non-markdown file,
# I've wrapped it in a proc which gets lazily loaded by `render_markdown` when needed.
#

BLACKCARPET_INIT = proc do

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

    private def smash(s)
      s&.downcase&.scan(/\w+/)&.join
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

    def block_code(code, language)
      language ||= :ruby

      language = language[1..-1] if language[0] == "."  # strip leading "."
      language = :cpp if language == "C++"

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


HTMLENTITIES = {
  'nbsp'  => ' ',
  'ndash' => '-',
  'mdash' => '-',
  'amp'   => '&',
  'raquo' => '>>',
  'laquo' => '<<',
  'quot'  => '"',
  'micro' => 'u',
  'copy'  => '(c)',
  'trade' => '(tm)',
  'reg'   => '(R)',
  '#174'  => '(R)',
  '#8212' => '--',
  '#8230' => '--',
  '#8220' => '"',
  '#8221' => '"',
  '#39'   => "'",
  '#8217' => "'",
}

def convert_htmlentities(s)
  s.gsub(/&([#\w]+);/) { HTMLENTITIES[$1] || $0 }
end

def print_markdown(markdown)
  # Lazily load markdown renderer
  begin
    require 'epitools/colored'
    require 'redcarpet'
  rescue LoadError
    return "\e[31m\e[1mNOTE: For colorized Markdown files, 'gem install epitools redcarpet'\e[0m\n\n" \
      + print_source(filename)
  end

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

def print_moin(moin)

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
    gsub(/\{\{attachment:(.+)\}\}/, "![](\\1)").  # images
    gsub(/\[\[(.+)\|(.+)\]\]/, "[\\2](\\1)").     # links w/ desc
    gsub(/\[\[(.+)\]\]/, "[\\1](\\1)").           # links w/o desc
    gsub(/^#acl .+$/, '').                        # remove ACLs
    gsub(/^<<TableOfContents.+$/, '').            # remove TOCs
    gsub(/^## page was renamed from .+$/, '').    # remove 'page was renamed'
    gsub(/^\{\{\{\n^#!raw\n(.+)\}\}\}$/m, "\\1"). # remove {{{#!raw}}}s
    # TODO: convert {{{\n#!highlight lang}}}s (2-phase: match {{{ }}}'s, then match first line inside)
    gsub(/^\{\{\{#!highlight (\w+)\n(.+)\n\}\}\}$/m, "```\\1\n\\2\n```"). # convert {{{#!highlight lang }}} to ```lang ```
    gsub(/^\{\{\{\n(.+)\n\}\}\}$/m, "```\n\\1\n```")  # convert {{{ }}} to ``` ```

  markdown = convert_tables[markdown]

  print_markdown(markdown)
end

##############################################################################

# def print_textile(filename)
#   require 'redcloth'
# end

##############################################################################

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

def print_rst(filename)
  run("rst2ansi", filename)
end

##############################################################################

def tmp_filename(prefix="c", length=20)
  chars = [*'a'..'z'] + [*'A'..'Z'] + [*'0'..'9']
  name  = nil
  loop do
    name = "/tmp/#{prefix}-#{length.times.map { chars.sample }.join}"
    break unless File.exists?(name)
  end
  name
end

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

def print_ipynb(filename)
  require 'json'
  require 'tempfile'

  json = JSON.load(open(filename))
  tmp = Tempfile.new('c-')

  json["cells"].each do |c|
    case c["cell_type"]
    when "markdown"
      tmp.write "#{c["source"].join}\n\n"
    when "code"
      # FIXME: Hardwired to python; check if a cell's metadata attribute supports other languages
      tmp.write "\n```python\n#{c["source"].join}\n```\n\n"
    else
      raise "unknown cell type: #{c["cell_type"]}"
    end
  end

  at_exit { tmp.unlink }

  print_markdown(File.read tmp.path)
end

##############################################################################

def print_torrent(filename)
  require 'bencode'
  require 'digest/sha1'

  data = BEncode.load_file(filename)

  # require 'awesome_print'; return data.ai

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

def print_cp437(filename)
  open(filename, "r:cp437:utf-8", &:read).gsub("\r", "")
end

##############################################################################

def print_obj(filename)
  highlight_lines_with_colons(run("objdump", "-xT", filename))
end

##############################################################################

def print_ssl_certificate(filename)
  #IO.popen(["openssl", "x509", "-in", filename, "-noout", "-text"], "r")
  highlight_lines_with_colons(run("openssl", "x509", "-fingerprint", "-text", "-noout", "-in", filename, ))
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

def pretty_xml(data)
  require "rexml/document"

  result    = ""
  doc       = REXML::Document.new(data)
  formatter = REXML::Formatters::Pretty.new

  formatter.compact = true # use as little whitespace as possible
  formatter.write(doc, result)

  result
end

##############################################################################

def print_archive(filename)
  run("atool", "-l", filename)
end

def print_archived_xml_file(archive, internal_file)
  # internal_ext = File.extname(internal_file)
  case archive.extname
  when ".k3b"
    data = IO.popen(["unzip", "-p", archive.to_s, internal_file]) { |io| io.read }
    CodeRay.scan(pretty_xml(data), :xml).term
  end
end

##############################################################################

def print_bibtex(filename)
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
  IO.popen(["lynx", "-dump", url]) { |io| io.read }
end

def print_html(file)
  # TODO: Is it better to use Term.width as html2text's -b option?
  ansi = IO.popen(["html2text", "-b", "0"], "r+") do |markdown|
    markdown.write File.read(file)
    markdown.close_write
    print_markdown(markdown.read)
  end
end

##############################################################################

def highlight(enum, &block)
  Enumerator.new do |y|
    enum.each do |line|
      y << block.call(line)
    end
  end
end

def highlight_lines_with_colons(enum)
  highlight(enum) do |line|
    if line =~ /^(\S+.*):(.*)/
      "\e[37;1m#{$1}\e[0m: #{$2}"
    else
      line
    end
  end
end

##############################################################################

COMPRESSORS = {
  ".gz"  => %w[gzip -d -c],
  ".xz"  => %w[xz -d -c],
  ".bz2" => %w[bzip2 -d -c],
}


def convert(arg)

  if arg =~ %r{^https?://.+}
    print_http(arg)
  else
    arg = which(arg) unless File.exists? arg

    return "\e[31m\e[1mFile not found.\e[0m" unless arg

    #
    # If it's a directory, show the README, or print an error message.
    #
    if File.directory? arg
      readmes = Dir.foreach(arg).select { |f| f[/^readme/i] or f == "PKGBUILD" }.sort_by(&:size)
      if readme = readmes.first
        return convert("#{arg}/#{readme}")
      else
        return run("tree", arg)
        # return "\e[31m\e[1mThat's a directory!\e[0m"
      end
    end

    path = Pathname.new(arg)

    # TODO: Fix relative symlinks
    # arg = File.readlink(arg) if File.symlink?(arg)

    # MEGA SWITCH STATEMENT
    ext = path.extname.downcase

    if path.filename =~ /\.tar\.(gz|xz|bz2|lz|lzma|pxz|pixz|lrz)$/ or
       ext =~ /\.(tgz|tar|zip|rar|arj|lzh|deb|rpm|7z|epub|xpi|apk|pk3|jar|gem)$/
      print_archive(arg)
    elsif cmd = COMPRESSORS[ext]
      run(*cmd, arg)
    elsif path.filename =~ /.+-current\.xml$/
      print_wikidump(arg)
    else
      case ext
      when *%w[.html .htm]
        print_html(arg)
      when *%w[.md .markdown .mdwn .page]
        print_markdown(File.read arg)
      when *%w[.moin]
        print_moin(File.read arg)
      when *%w[.ipynb]
        print_ipynb(arg)
      when /^\.[1-9]$/ # manpages
        system("man", "-l", arg)
      when *%w[.torrent]
        print_torrent(arg)
      when *%w[.nfo .ans .drk .ice]
        print_cp437(arg)
      when *%w[.rst]
        print_rst(arg)
      when *%w[.doc]
        print_doc(arg)
      when *%w[.pem .crt]
        print_ssl_certificate(arg)
      when *%w[.xml]
        print_source(arg).gsub(/&[\w\d#]+?;/, HTML_ENTITIES)
      when *%w[.csv .xls]
        print_csv(arg)
      when ".tsv"
        print_csv(arg)
        # print_csv(arg, "\t") # it autodetects now. (kept for posterity)
      when ".bib"
        print_bibtex(arg)
      when ".k3b"
        print_archived_xml_file(path, "maindata.xml")
      else
        format = run('file', arg).read

        case format
        when /POSIX shell script/
          print_source(arg)
        when /:.+?(executable|shared object)[^,]*,/
          print_obj(arg)
        when /(image,|image data)/
          show_image(arg)
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

  if args.size == 0
    puts "usage: c <filename(s)>"
  else # 1 or more args

    wrap = !args.any? { |arg| arg[/\.csv$/i] }
    scrollable = args.delete("-s")

    lesspipe(:wrap=>wrap, :clear=>!scrollable) do |less|

      args.each do |arg|
        if args.size > 1
          less.puts "\e[30m\e[1m=== \e[0m\e[36m\e[1m#{arg} \e[0m\e[30m\e[1m==============\e[0m"
          less.puts
        end

        begin
          result = convert(arg)
        rescue Errno::EACCES
          puts "\e[31m\e[1mNo read permission for \e[0m\e[33m\e[1m#{arg}\e[0m"
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
      end
    end

  end

end
