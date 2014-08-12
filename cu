#!/usr/bin/env ruby
##########################################################################
## cu: certutil util
##########################################################################

require 'epitools'

def title(s)
  msg = "<8>== <11>#{s} <8>#{"="*(100-s.size)}"
  puts
  puts msg.colorize
  puts
end

def usage
  cols = COMMANDS.map do |name, opts|
    cmdpart = name
    if optstr = opts[:options]
      optstr = optstr.join " " if optstr.is_a? Array
      cmdpart += " " + optstr
    end
  
    ["cu #{cmdpart}", "#{opts[:desc]}"]
  end
  
  table = Term::Table.new(cols)
  puts table.by_columns
end  

#
# Returns a string that looks like:
#   "-----BEGIN CERTIFICATE-----\n<cert>\n-----END CERTIFICATE-----"
#
def get_website_cert(host, port=nil)
  port = 443 if port.nil? or port.to_i == 80
  
  `echo | openssl s_client -connect #{hostport} 2>&1 |sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'`
end

def import_cert(urlorfile)
    
  if urlorfile =~ %r{(.+\.(?:com|org|net|info|ca|de|uk))(:\d+)?}
    host, port = $1, $2 || "443"
    cert = get_website_cert(host, port)
  else
    path = Path[urlorfile]
    if path.url?
      cert = get_website_cert(path.host, path.port)
    elsif path.exists?
      cert = path.read
    end
  end

  p [:cert, cert]
  
  out = Path.tmpfile
  out << cert
  certutil "-A -t 'P,,' -n #{host} -i #{out}"
  # "certutil -d sql:$HOME/.pki/nssdb -A -t "P,," -n <certificate nickname> -i <certificate filename>"
end

COMMANDS = {
  "list" => {
     desc: "show all keys",
     action: proc do
       title "Private Keys"
       certutil "-K"
       title "Certificates"
       certutil "-L" 
     end
  },
  "modules" => {
    desc: "show all modules",
    action: proc do
      certutil "-U"
    end
  },
  "add" => {
    desc: "add certificate to the database",
    options: "<url or file>",
    action: proc do |urlorfile|
      cert_for_url uri = URI.parse(urlorfile)
      if uri.path and not uri.host
        # import a file
      else
        # import a URL
      end
      certutil "-U" 
    end
  }
}

def certutil(*args)
  if args.size == 1 and 
      newargs = args.first.split and 
      newargs.size > 0
    args = newargs
  end
  
  cmd = ["certutil", "-d", "sql:#{ENV['HOME']}/.pki/nssdb"] + args
  system(*cmd)
end

if $0 == __FILE__
  args = ARGV

  if args.empty?
    usage
    exit 1
  end
  
  command_name = args.shift
  
  if opts = COMMANDS[command_name]
    puts "== #{opts[:desc]} ==="
    opts[:action].call(*args)
  else
    puts "Error: #{command_name} not found"
  end
end
