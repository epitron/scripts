#!/usr/bin/env ruby
require 'epitools'
require 'slop'

__version__ = '0.1'


class Extractor
end

class Zip
end

# file or url?
# url:
#   find filename/type
#     * name in url?
#       Whee!
#     * otherwise magic!
# file:
#   * determine type
#
#   get extractor
#   extracts streams?
#     * extract it!
#   otherwise
#     
#     
#   


archive "zip", :aka=>%w[pk3 jar], :mime=>""

class Archive
  
  def type_of_stream(start_of_archive)
    MimeMagic.by_magic StringIO.new(start_of_archive)
  end
  
end


Archive.define_types

# Two kinds of type definitions:
#   declarative (define binary and commands)
#     * identifies mime type
#     * tries to find program to extract
#       * install package if missing
#     * creates destination directory
#     *  
#   custom block (have access to the internal api and extract it with a custom algorithm)


  type 'application/x-gzip' do |archive|
    streamable_handle = archive.io
    identify = streamable_handle.read(500)
    
    extract_file "gunzip -c %archive > %dest"
    extract_pipe "gunzip -c - > %dest"
    streamable!
    pipeable!

    package_deps :all=>"gzip"
  end
  
  type 'application/x-compressed-tar' do
    exts %w[tar.gz tgz taz]
    desc "Tar archive (gzip-compressed)"
    command "tar", "zxvf"
    command "tar zxvf %archive %dest"
    streamable!
  end

  type 'application/x-arj' do
    exts %w(arj)
    desc "ARJ archive"
    package_deps :debian=>"p7zip-full"
    command "7z x %archive %dest"
  end
    
end


    'application/x-arj' => [%w(arj), %w(), "ARJ archive"],
    'application/x-bzip' => [%w(bz2 bz), %w(), "Bzip archive"],
    'application/x-compressed-tar' => [%w(tar.gz tgz taz), %w(), "Tar archive (gzip-compressed)"],
    'application/x-rar' => [%w(rar), %w(), "RAR archive"],
    'application/x-rpm' => [%w(rpm), %w(), "RPM package"],
    'application/x-deb' => [%w(deb), %w(), "Debian package"],

{
  :zip => {
    :exts            => ['.zip', '.pk3', '.jar'],
    :desc            => "ZIP file",
    :binary          => "unzip",
    :package         => "unzip",
  }
}

__DATA__

Example usage:

  $ x <archive/url>
  => extract archive to <archive basename>/
  
  $ x <archive/url> <dest>
  => extract archive to <dest>/
       - if <dest> is a dir, extracts to <dest>/<archive basename>
       - if <dest> isn't a dir yet, <dest> is created and the archive contents go into <dest>/

  $ x l <archive/url>
  => list archive

  $ x c <archive> <src> [<src>, ...]
  => create <archive> from one or more <src>

    
    
def usage
  puts 'This program takes a compressed file from an url or a filename, figures out'
  puts 'what type of file it is, then tries to extract it into a directory.'
  puts
  exts = []
  for extractor in extractors:
      exts.extend(extractor.exts)
  puts 'Supported filetypes:\n    %s' % ', '.join(exts)
  puts
  puts 'Usage:'
  puts '    x <input file or url> [output directory]'
  puts
  puts 'The [output directory] is optional. By default, the current directory is used.'
  puts
end


