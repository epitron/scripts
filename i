#!/usr/bin/env ruby

#######################################################################
# TODOs:
# - after starting the service, tail the status log (through less (until the user hits "q"))
# - "start" => start + status
# - "enable" => enable + start
# - Fuzzy matching when script isn't found
#######################################################################

def running_as_root?
  Process.uid == 0
end

#######################################################################

class Systemd

  def initialize(user_mode=false)
    @user_mode = user_mode
  end

  def user_mode?; @user_mode; end

  def self.detected?
    system("pidof systemd > /dev/null")
  end

  def systemctl(*args)
    opts = args.last.is_a?(Hash) ? args.pop : {}

    cmd = if user_mode?
            %w[systemctl --user]
          else
            if running_as_root? or !opts[:sudo]
              %w[systemctl]
            else
              %w[sudo systemctl]
            end
          end

    cmd += args

    puts
    print "\e[30m\e[1m=>"
    print " \e[36m\e[1m#{opts[:msg]}" if opts[:msg]
    puts  " \e[30m\e[1m(\e[34m\e[1m#{cmd.join(" ")}\e[30m\e[1m)\e[0m"
    puts
    system *cmd
  end

  def services
    # lines = `systemctl --all -t service`.lines.map(&:strip)[1..-1].split_before{|l| l.blank? }.first
    # lines.map { |line| line.split.first.gsub(/\.service$/, "") }.reject { |s| s[/^(systemd-|console-kit|dbus-org)/] or s[/@$/] }
    systemctl("list-unit-files", msg: "Units", sudo: false)
  end

  def search(query)
    systemctl("list-unit-files", query, msg: "Searching for: #{query}")
  end

  def reload
    systemctl("daemon-reload", msg: "Reloading systemd configuration")
  end

  def reexec
    systemctl("daemon-reexec", msg: "Reexecuting systemd")
  end

  # "command1>command2" means to call command2 whenever command1 is called
  # something starting with a ":" means to call a method
  %w[start>status stop>status restart>status disable>stop enable>:start mask>stop>status unmask>start>status].each do |command|
    commands = command.split(">")

    define_method commands.first do |service|
      commands.each do |command|
        case command
        when /^:(.+)$/
          send($1, service)
        else
          systemctl command, service
        end
      end
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

  def status(service, amount=nil)
    cmd = ["status", "-l"]
    cmd += ["-n", amount.to_s] if amount
    cmd << service

    systemctl *cmd, msg: "Status of: #{service}"
  end

  def default
    services
  end

  def default_command(service)
    status(service, 33)
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
    cmd = ["#{@initdir}/#{service}", command]
    cmd = ["sudo", *cmd] unless running_as_root?
    system *cmd
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

    regexp = Regexp.new(query)

    puts "Services (search query: /#{regexp}/):"
    puts "================================================="

    highlighted = services.map { |s| s.highlight(query) if query =~ s }.compact

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

class Runit

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
    cmd = ["#{@initdir}/#{service}", command]
    cmd = ["sudo", *cmd] unless running_as_root?
    system *cmd
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

    puts "Services (filtered by /#{query}/):"
    puts "================================================="

    highlighted = services.map { |s| s.highlight(query) if query =~ s }.compact

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

args = ARGV

if Systemd.detected?
  manager = Systemd.new( args.delete("--user") )
else
  manager = Initd.new
end

# Parse args
if args.empty? # No args
  manager.default
elsif args.any? { |arg| ["reload", "daemon-reload"].include? arg }
  manager.reload
elsif args.first =~ %r{/(.+?)/}
  manager.search("*#{$1}*")
else
  case args.size
  when 2
    service, command = args
  when 1
    service, command = args.first, "default_command"
  end

  manager.send(command, service)
end
