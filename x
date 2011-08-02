#!/usr/bin/env ruby
require 'epitools'
require 'slop'

__version__ = '0.1'


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

{
  :zip => {
    :exts            => ['.zip', '.pk3', '.jar'],
    :streamable      => false,
    :desc            => "ZIP file",
    :binary          => "unzip",
    :package         => "unzip",
  }
}




