#!/usr/bin/env ruby
#####################################################################################
#
# This script displays and edits xattrs (extended attributes, or metadata) on files.
#
#####################################################################################
#
# TODO:
#
# * Batch edit
# * Batch getfattr
#
#####################################################################################

require 'epitools'

#####################################################################################

class FakeOptions
  def method_missing(*args); nil; end
end

#####################################################################################

def hash_diff(h1, h2)
  {
    updated:   ((h1.to_a ^ h2.to_a) - h1.to_a).map(&:first),
    deleted: h1.keys - h2.keys
  }
end

#####################################################################################

def edit(path)
  tmp       = Path.tmp
  old_attrs = path.attrs

  tmp.write old_attrs.to_yaml

  system(ENV["EDITOR"] || "nano", tmp)

  new_attrs = tmp.read_yaml
  diff      = hash_diff(old_attrs, new_attrs)
  
  diff[:updated].each do |key|
    path[key] = new_attrs[key]
  end

  diff[:deleted].each do |key|
    path[key] = nil
  end

  path
end

#####################################################################################

def show(path)

  if (attrs = path.attrs).any?
    puts "<15>#{path.filename}".colorize
    attrs.each do |k,v|
      puts "  <9>#{k} <8>=> <11>#{v}".colorize
    end
    puts
  else
    puts "<7>#{path.filename}".colorize
  end
end

#####################################################################################
# OPTION PARSER

def parse_options
  require 'slop' # lazy loaded
  @opts = Slop.parse(help: true, strict: true) do
    banner "xattr editor\n\nUsage: x [options] <files...>"

    on 'e',  'edit',      'Edit xattrs (with $EDITOR)'
    on 'u=', 'url',       'Set origin URL (user.xdg.origin.url)'
    on 'r=', 'referrer',  'Set referrer URL (user.xdg.referrer.url)'

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

  if opts.url? or opts.referrer?

    assert paths.size == 1, "Must supply exactly one filename."

    path = paths.first

    if opts.url?
      path["user.xdg.origin.url"] = opts[:url]
    elsif opts.referrer?
      path["user.xdg.referrer.url"] = opts[:referrer]
    end

    show path

  else

    paths << Path.pwd if paths.empty?

    while paths.any?
      path = paths.shift

      if path.dir?

        puts "* Scanning #{path}..."
        paths += path.ls

      else      

        edit(path) if opts.edit?
        show(path)

      end
    end

  end

end

#####################################################################################
