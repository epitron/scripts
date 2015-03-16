#!/usr/bin/env ruby

#######################################################################
#
# TODO: Fuzzy matching when script isn't found
#
#######################################################################

args = ARGV

#######################################################################

class Systemd

  def initialize(user=false)
    @user = user
  end

  def self.detected?
    system("pidof systemd > /dev/null")
  end

  def systemctl(*args)
    if @user
      cmd = %w[systemctl --user]
    else
      cmd = %w[sudoifnotroot systemctl]
    end
    
    cmd += args

    puts "=> #{cmd.join(" ")}"
    puts
    system *cmd
  end

  def services
    # lines = `systemctl --all -t service`.lines.map(&:strip)[1..-1].split_before{|l| l.blank? }.first
    # lines.map { |line| line.split.first.gsub(/\.service$/, "") }.reject { |s| s[/^(systemd-|console-kit|dbus-org)/] or s[/@$/] }
    systemctl("list-unit-files")
  end

  def reload
    systemctl("daemon-reload")
  end

  %w[start stop restart disable enable].each do |command|
    define_method command do |service|
      systemctl command, service
    end
  end

  # def start(service)
  #   systemctl "start", service
  # end

  # def stop(service)
  #   systemctl "stop", service
  # end

  # def restart(service)
  #   systemctl "restart", service
  # end

  def status(service)
    systemctl "status", "-l", service
  end

  def default
    services
  end

  def search(query)
    raise "Search not implemented for systemd."
  end

  def default_command(service)
    status(service)
  end

end

#######################################################################

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

  def reload
    puts "Reload not needed for init.d"
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

  def search(query)
    require 'epitools'

    puts "Services (filtered by /#{$1}/):"
    puts "================================================="

    
    highlighted = sys.services.map { |s| s.highlight(query) if query =~ s }.compact

    puts Term::Table.new(highlighted, :ansi=>true).by_columns
  end

  def default
    require 'epitools'

    puts "Services:"
    puts "============================="

    puts Term::Table.new(services).by_columns
  end

  def default_command(service)
    restart(service)
  end

end

#######################################################################

## Detection of systemd/init.d
if Systemd.detected?
  if ARGV.first == "--user"
    ARGV.shift
    manager = Systemd.new(true)
  else
    manager = Systemd.new
  end
else
  manager = Initd.new
end


if args.empty? # No args

  manager.default

elsif args == ["reload"]

  manager.reload

elsif args.first =~ %r{/(.+?)/}

  query = Regexp.new($1)
  manager.search(query)

else

  case args.size
  when 2
    service, command = args
  when 1
    service, command = args.first, "default_command"
  end

  manager.send(command, service)

end