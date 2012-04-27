#!/usr/bin/env ruby

# TODO: If script is not found, show close matches.

args = ARGV

if args.empty? # No args

	require 'epitools'
	scripts = Path["/etc/init.d/*"].map(&:filename).sort

	puts "Init scripts:"
	puts "============================="

	puts Term::Table.new(scripts).by_columns

elsif args.first =~ %r{/(.+?)/}

	require 'epitools'
	scripts = Path["/etc/init.d/*"].map(&:filename).sort

	puts "Init scripts (filtered by /#{$1}/):"
	puts "================================================="

	query       = Regexp.new($1)
	highlighted = scripts.map { |s| s.highlight(query) if query =~ s }.compact

	puts Term::Table.new(highlighted, :ansi=>true).by_columns

else

	case args.size
	when 2
		daemon, command = args
	when 1
		daemon, command = args.first, "restart"
	end

	system("sudoifnotroot", "/etc/init.d/#{daemon}", "#{command}")

end		

=begin
if ARGV.first[ "$1" == "" ]
then
	echo "Init scripts:"
	echo "============================="
	ls /etc/init.d
else
	if [ "$2" == "" ]
	then
		CMD="restart"
	else
		CMD="$2"
	fi

	sudoifnotroot /etc/init.d/$1 $CMD
fi
=end