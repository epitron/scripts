#!/usr/bin/ruby

# The program e is a command line utility that extracts lots of
# different archives. It is very simple and can be extended very easily.
#
# It is inspired by how firewall use their rulesets, and works like this:
# 
# * For each file that has to be extracted, the rules are matched one after the other.
# * When a rule matches (either by the filetype or filename), the command is executed.
# * If the command does not return an error code  the extraction is considered successful, otherwise the next rules are matched.
#
# It currently has rules for zip, rar, 7zip, gzip, bzip2, rpm, cab, arj, ace, ppmd, lzo, tar.bz2, tar.gz, ...
#
# Author:: Martin Ankerl (mailto:martin.ankerl@gmail.com)
# Copyright:: Copyright (c) 2006 Martin Ankerl
# Date:: 2006-08-12
# License:: public domain
#
# Homepage:: http://martin.ankerl.org/


# Each rule consists of 3 parts:
#
# 1. type of the match: currently either :name or :type. If you use :name, then the regular expression
# is matched against the filename. If you use :type, the regular expression is matched against the
# output of the "file" command. Usually :type is a better choice because you are independent from the
# actual filename, but for file types that cannot be detected use :name.
#
# 2. The regular expression is used in a match. If the regular expression matches, the command
# (3rd parameter of the rule) is executed.
#
# 3. The command to execute. %FILE% is replaced by the filename (with apostrophe).
#
# On extraction, each of the rules are matched one after the other. The command of 
# the first rule that matches is executed. If the executed command does not return an
# error code, extraction was successful. If the command could not be executed (e.g. if do not
# have unrar but only rar) or returns with an error code, the next rules are matched until
# either no rule is available any more, or extraction was successful.
#
rules = Array.new
rules.push [ :name, /(\.tar\.gz|\.tgz)$/, "tar xzvf %FILE%" ]
rules.push [ :name, /(\.tar\.bz2|\.tbz)$/, "tar xjvf %FILE%" ]
rules.push [ :name, /(\.tar\.lzo|\.tzo|\.tar\.lzop)$/, "lzop -c -d %FILE% |tar -xv" ]
rules.push [ :type, /tar archive/, "tar -xvf %FILE%" ]
rules.push [ :type, /^Zip archive/, "unzip %FILE%" ]
rules.push [ :type, /^7-zip/, "7z x %FILE%" ]
rules.push [ :type, /^RAR archive/, "unrar x -o+ %FILE%" ]
rules.push [ :type, /^RAR archive/, "rar e %FILE%" ]
rules.push [ :type, /^Debian.*package/, "dpkg -x %FILE% ." ]
rules.push [ :type, /^Debian.*package/, "ar -x %FILE%" ]
rules.push [ :type, /^lzop /, "lzop -x -f %FILE%" ]
rules.push [ :name, /\.rz$/, "rzip -d -k -v %FILE%" ]
rules.push [ :type, /gzip /, "gzip -d %FILE%" ] # TODO gzip is the only operation that removes the original file
rules.push [ :type, /bzip2 /, "bzip2 -dk %FILE%" ]
rules.push [ :type, /^RPM/, "rpm2cpio < %FILE% | cpio -i -d --verbose" ]
rules.push [ :type, /\ ar archive/, "ar xv %FILE%" ]
rules.push [ :type, /^LHarc /, "lha x %FILE%" ]
rules.push [ :type, /^ARJ /, "arj x %FILE%" ]
rules.push [ :type, /MS CAB-Installer/, "cabextract %FILE%" ]
rules.push [ :type, /^ACE /, "unace e %FILE%" ]
rules.push [ :type, /^PPMD archive/, "ppmd d %FILE%" ]
rules.push [ :name, /(\.tar\.lzma|\.tlz)$/, "lzma d -si -so < %FILE% |tar -xv" ]

# check arguments
if ARGV.empty?
	puts "usage: e archive [ archive archive ...]"
	exit 0
end

# extract each archive
ARGV.each do |filename|
	# get filetype
	filenameWithComma = '"' + filename + '"'
	filetype = `file -b #{filenameWithComma}`
	
	# find command
	extractionSuccess = rules.find do |matchType, regexp, command|
		# find out if it is matching
		doesMatch = case matchType
		when :name then regexp.match(filename)
		when :type then regexp.match(filetype)
		end

		# only return true if extraction was successful (to stop find)
		if doesMatch
			# matching rule found, try to extract
			executable = command.gsub("%FILE%", filenameWithComma)

			# returns true if execution was successful
			system(executable)
		else
			false
		end
	end
	
	# no extraction attempt completed successful, show error message
	if extractionSuccess.nil?
		puts ""
		puts "ERROR extraction not successful"
		system("file #{filenameWithComma}")
		exit 1
	end
end
