#!/usr/bin/env ruby
#####################################################################################
#
# This script displays and edits xattrs (extended attributes, or metadata) on files.
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
  puts "<15>#{path.filename}".colorize
  path.attrs.each do |k,v|
    puts "  <9>#{k} <8>=> <11>#{v}".colorize
  end
  puts
end

#####################################################################################
# OPTION PARSER

def parse_options
  require 'slop' # lazy loaded
  @opts = Slop.parse(help: true, strict: true) do
    banner "xattr editor\n\nUsage: x [options] <files...>"

    on 'e',  'edit',  'Edit xattrs'
  end
end

#####################################################################################

if $0 == __FILE__

  if ARGV.empty? or ARGV.any? { |opt| opt[/^-/] }
    opts = parse_options
  else
    opts = FakeOptions.new
  end

  unless ARGV.any?
    puts "Error: Must supply at least one file."
    puts
    puts parse_options
    exit 1
  end

  paths = ARGV.map(&:to_Path)

  paths.each do |path|
    if opts.edit?
      edit(path)
      show(path)
    else
      show(path)
    end
  end
end

#####################################################################################
