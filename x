#!/usr/bin/env ruby
#####################################################################################
#
# This script displays and edits xattrs (extended attributes, or metadata) on files.
#
#####################################################################################
#
# TODO:
#
# * Accepted nested YAML as input (eg: user.dublincore: attr: <value>)
# * Instead of printing "Scanning...", just print paths relative to PWD
# * Batch getfattr
#
#####################################################################################

gem 'epitools', '>= 0.5.46'
require 'epitools'

#####################################################################################

class FakeOptions
  def method_missing(*args); nil; end
end

#####################################################################################

COMMON_KEYS = %w[
  user.dublincore.title 
  user.dublincore.creator
  user.dublincore.subject 
  user.dublincore.description 
  user.dublincore.publisher 
  user.dublincore.contributor 
  user.dublincore.date 
  user.dublincore.type 
  user.dublincore.format 
  user.dublincore.identifier 
  user.dublincore.source 
  user.dublincore.language
  user.dublincore.relation 
  user.dublincore.coverage 
  user.dublincore.rights
  user.xdg.referrer.url
  user.xdg.origin.url
]

#####################################################################################

def edit(path)
  tmp = Path.tmp
  
  tmp.io("w") do |f|
    f.puts(path.attrs.to_yaml) if path.attrs.any?
    f.puts
    f.puts "#"
    f.puts "# Editing xattrs for #{path}"
    f.puts "# -----------------------------------------"
    f.puts "# Type in xattrs in this format (YAML):"
    f.puts "#    user.custom.attr: This is a custom attribute."
    f.puts "#    user.xdg.referrer.url: http://site.com/path/"
    f.puts "#"
    f.puts "# (Note: custom attributes must begin with 'user.')"
    f.puts "#"
    f.puts "# Enter your attributes at the top of the file."
    f.puts "#"
    f.puts "# Examples:"
    f.puts "#"
    COMMON_KEYS.each { |key| f.puts "##{key}: "}
    f.puts "#"
  end

  cmd = (ENV["EDITOR"] || "nano").split
  cmd << tmp

  system *cmd

  path.attrs = tmp.read_yaml

  path
end

#####################################################################################

def translate_value(key, value)
  case key
  when "security.capability"
    # struct vfs_cap_data_disk {
    #   __le32 version;
    #   __le32 effective;
    #   __le32 permitted;
    #   __le32 inheritable;
    # };

    bitmaps = [:effective, :permitted, :inheritable]

    version, *maps = value.unpack("L*")

    "#{value.bytes.size} v#{version}, maps: #{maps.inspect}"
  else
    value
  end
end


def show(path, format=:text, timestamp=false)
  if not path.exists?

    puts "<7>#{path.filename} <8>(<12>not found<8>)".colorize

  elsif (attrs = path.attrs).any?
    title = "<15>#{path.filename}"
    title += " <6>[<14>#{path.mtime.strftime("%b %d, %Y")}<6>]" if timestamp

    puts title.colorize

    case format
    when :text
      grouped = attrs.
                map { |k, v| [k.split("."), translate_value(k, v)] }.
                sort.
                group_by { |k,v| k[0..1] } # first 2 parts of the key

      grouped.each do |first_2_namespaces, attrs_in_namespace|
        primary_namespace = first_2_namespaces.first

        case primary_namespace
        when "security"
          a,b = 4,12
        when "trusted"
          a,b = 5,13
        when "user"
          a,b = 3,11
        else
          a,b = 8,15
        end

        puts "  <#{a}>[<#{b}>#{first_2_namespaces.join('.')}<#{a}>]".colorize
        attrs_in_namespace.each do |attr, value|
          sub_namespace = attr[2..-1].join('.')
          puts "    <9>#{sub_namespace}<8>: <7>#{value}".colorize
        end
      end

      puts

    when :yaml
      puts attrs.to_yaml

    when :json
      puts attrs.to_json

    end

  else
    puts "<7>#{path.filename}\n  <8>(none)\n".colorize
  end
end

#####################################################################################
# OPTION PARSER

def parse_options
  require 'slop' # lazy loaded
  @opts = Slop.parse(help: true, strict: true) do
    banner "xattr editor\n\nUsage: x [options] <files...>"

    on 'e',  'edit',      'Edit xattrs (with $EDITOR)'
    on 'c',  'copy',      'Copy xattrs from one file to another (ERASING the original xattrs)'
    on 'm',  'merge',     'Overlay xattrs from one file onto another (overwriting only the pre-existing attrs)'
    on 'y',  'yaml',      'Print xattrs as YAML'
    on 'j',  'json',      'Print xattrs as JSON'
    on 'u=', 'url',       'Set origin URL (user.xdg.origin.url)'
    on 'r=', 'referrer',  'Set referrer URL (user.xdg.referrer.url)'
    on 't',  'time',      'Sort by file timestamp'

  end
end

#####################################################################################

def assert(expr, error_message)
  raise error_message unless expr
end


if $0 == __FILE__

  if ARGV.empty? or ARGV.any? { |opt| opt[/^-/] }
    opts = parse_options
  else
    opts = FakeOptions.new
  end

  paths = ARGV.map(&:to_Path)

  # TODO: constraints on arguments (eg: must supply exactly one file, mutually exclusive commands)
  # TODO: bult setting of url/referrer (create a YAML file with all the urls blank)

  # Copy attrs from one file to another
  if opts.copy? or opts.merge?

    assert paths.size == 2, "Must supply exactly two filenames: a source, and a destination."

    src, dest = paths

    if opts.merge?
      dest.attrs = dest.attrs.update(src.attrs)
    else
      dest.attrs = src.attrs
    end

    show(dest)

  # Set the URL or REFERRER attrs
  elsif opts.url? or opts.referrer?

    assert paths.size == 1, "Must supply exactly one filename."

    path = paths.first

    if opts.url?
      path["user.xdg.origin.url"] = opts[:url]
    elsif opts.referrer?
      path["user.xdg.referrer.url"] = opts[:referrer]
    end

    show path

  # EDIT or SHOW attrs
  else

    paths << Path.pwd if paths.empty?

    paths = paths.map { |path| path.dir? ? path.ls : path }.flatten
    paths = paths.sort_by(&:mtime) if opts.time?

    paths.each do |path|
      edit(path) if opts.edit?

      if opts.yaml?
        format = :yaml
      elsif opts.json?
        format = :json
      else
        format = :text
      end

      show(path, format, timestamp: true)
    end

  end

end

#####################################################################################
