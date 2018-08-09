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
# OPTION PARSER

def parse_options
  gem 'slop', '~> 3.6'
  require 'slop' # lazy loaded
  @opts = Slop.parse(help: true, strict: true) do
    banner "xattr editor\n\nUsage: x [options] <files...>"

    on 's=', 'set',       'Set an attr (eg: "x -s dublincore.title=Something something.mp4")'
    on 'e',  'edit',      'Edit xattrs (with $EDITOR)'
    on 'c',  'copy',      'Copy xattrs from one file to another (ERASING the original xattrs)'
    on 'm',  'merge',     'Overlay xattrs from one file onto another (overwriting only the pre-existing attrs)'
    on 'y',  'yaml',      'Print xattrs as YAML'
    on 'j',  'json',      'Print xattrs as JSON'
    on 'u=', 'url',       'Set origin URL (user.xdg.origin.url)'
    on 'r=', 'referrer',  'Set referrer URL (user.xdg.referrer.url)'
    on 'R',  'recursive', 'Recurse into subdirectories'
    on 't',  'time',      'Sort by file timestamp'

  end
end

#####################################################################################

POPULAR_KEYS = %w[
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
  file = Tempfile.new('foo')

  file.puts(path.attrs.to_yaml) if path.attrs.any?
  file.puts
  file.puts "#"
  file.puts "# Editing xattrs for #{path}"
  file.puts "# -----------------------------------------"
  file.puts "# Type in xattrs in this format (YAML):"
  file.puts "#    user.custom.attr: This is a custom attribute."
  file.puts "#    user.xdg.referrer.url: http://site.com/path/"
  file.puts "#"
  file.puts "# (Note: custom attributes must begin with 'user.')"
  file.puts "#"
  file.puts "# Enter your attributes at the top of the file."
  file.puts "#"
  file.puts "# Examples:"
  file.puts "#"
  POPULAR_KEYS.each { |key| file.puts "##{key}: "}
  file.puts "#"
  file.close

  editor = (ENV["EDITOR"] || "nano").split
  system *editor, file.path

  path.attrs = Path[file.path].read_yaml

  file.unlink    # deletes the temp file

  path
end

#####################################################################################

def translate_value(key, value)
  case key
  when "user.com.dropbox.attributes"
    "#{value.size} bytes"
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


def show(path, timestamp=false)
  if path.dir?
    return
  elsif not path.exists?
    puts "<7>#{path.filename} <8>(<12>not found<8>)".colorize
  elsif (attrs = path.attrs).any?
    title = "<15>#{path.filename}"
    title += " <6>[<14>#{path.mtime.strftime("%b %d, %Y")}<6>]" if timestamp

    puts title.colorize

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

  else
    puts "<7>#{path.filename}\n  <8>(none)\n".colorize
  end
end

#####################################################################################

def assert(expr, error_message)
  raise error_message unless expr
end

def paths_as_hashes(paths)
  paths.map do |path|
    next if path.dir?
    {
      "filename" => path.filename,
      "dir" => path.dir,
      "mtime" => path.mtime,
      "size" => path.size,
      "xattrs" => path.xattrs,
    }
  end.compact
end

if $0 == __FILE__

  unless Path.which("getfattr")
    puts "'getfattr' not found in path. Please install the 'attr' package"
    exit 1
  end

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

  # Set the URL or REFERRER or CUSTOM (set) attrs
  elsif opts.url? or opts.referrer? or opts.set?

    assert paths.size == 1, "Must supply exactly one filename."

    path = paths.first

    if opts.set?
      key, val = opts[:set].split("=", 2)
      key = "user.#{key}" unless key[/^user\./]

      puts "* Setting '#{key}' to '#{val}'"

      path[key] = val
    elsif opts.url?
      path["user.xdg.origin.url"] = opts[:url]
    elsif opts.referrer?
      path["user.xdg.referrer.url"] = opts[:referrer]
    end

    show path

  # EDIT or SHOW attrs
  else

    paths << Path.pwd if paths.empty?

    paths = paths.map do |path|
      if path.dir?
        if opts.recursive?
          path.ls_r
        else
          path.ls
        end
      else
        path
      end
    end.flatten

    paths = paths.sort_by(&:mtime) if opts.time?

    if opts.yaml?
      puts YAML.dump(paths_as_hashes(paths))
    elsif opts.json?
      puts JSON.pretty_generate(paths_as_hashes(paths))
    else
      paths.each do |path|
        edit(path) if opts.edit?
        show(path, timestamp: true)
      end
    end

  end

end

#####################################################################################
