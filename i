#!/usr/bin/env ruby

# TODO: If script is not found, show close matches.

args = ARGV

class Initd

  def initialize
    @initdir = %w[
      /etc/init.d
      /etc/rc.d
    ].find {|dir| File.directory? dir }
  end

  def services
    Path["#{@initdir}/*"].map(&:filename).compact.sort
  end

  def run(service, command)
    system("sudoifnotroot", "#{@initdir}/#{service}", command)
  end

  def start(service)
    run(service, "start")
  end

  def stop(service)
    run(service, "stop")
  end

  def restart(service)
    run(service, "restart")
  end

end

class Systemd

  def services
    lines = `systemctl --all -t service`.lines.map(&:strip)[1..-1].split_before{|l| l.blank? }.first
    lines.map { |line| line.split.first.gsub(/\.service$/, "") }.reject { |s| s[/^(systemd-|console-kit|dbus-org)/] or s[/@$/] }
  end

  def run(service, command)
    system("sudoifnotroot systemctl")
  end

  def start(service)
    run(service, "start")
  end

  def stop(service)
    run(service, "stop")
  end

  def restart(service)
    run(service, "restart")
  end

end


sys = if system("pidof systemd > /dev/null")
  Systemd.new
else
  Initd.new
end

if args.empty? # No args

  require 'epitools'

  puts "Services:"
  puts "============================="

  puts Term::Table.new(sys.services).by_columns

elsif args.first =~ %r{/(.+?)/}

  require 'epitools'

  puts "Services (filtered by /#{$1}/):"
  puts "================================================="

  query       = Regexp.new($1)
  highlighted = sys.services.map { |s| s.highlight(query) if query =~ s }.compact

  puts Term::Table.new(highlighted, :ansi=>true).by_columns

else

  case args.size
  when 2
    service, command = args
  when 1
    service, command = args.first, "restart"
  end

  sys.send(command, service)

end