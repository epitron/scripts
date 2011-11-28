#!/usr/bin/env ruby
require 'epitools'
require 'slop'

opts = Slop.new :help => true do
  banner "Usage: dm -f from -t to [files...]"
  
  on :v, :verbose, 'Enable verbose mode'           
  on :n, :dryrun, 'Dry-run', false                  
  on :f, :from, 'From', :optional => false      
  on :t, :to, 'To', :optional => false  
end

## Handle arguments

#args = []
#opts.parse { |arg| args << arg }

uptime = Path["/proc/uptime"].lines.first.split.first.to_f
LAST_REBOOT = Time.now.to_f - uptime 

class Line < Struct.new(:secs, :text)
  def time
    Time.at(LAST_REBOOT + secs)
  end
end


#lines = Path["~/dmesg.txt"].lines.map do |line|
lines = `dmesg`.lines.map do |line|
  if line =~ /^\[(\d+.\d+)\] (.+)$/
    Line.new($1.to_f, $2)
  end
end.compact


def cluster_lines(lines)
  clusters = []
  cluster = [lines.first]
  
  lines.each_cons(2) do |a, b|
    delta = b.secs - a.secs
    
    if delta > 2
      clusters << cluster
      cluster = []
    end  
    
    cluster << b
  end
  
  clusters << cluster if cluster.any?
  
  clusters
end

class RepeatedString < String

  def repeats
    @repeats ||= 1
  end
  
  def repeats=(val)
    @repeats = val
  end
  
end

def group_repeats(cluster)
  repeats = 0
  newcluster = []
  cluster.map{|e| [e]}.each_cons(2) do |a, b|
    if a.first == b.first
      a << b
      b.remove
    end  
    if a.text == b.text
      repeats += 1
    end
  end
end

#r = RepeatedString.new("hello")
#p r
#p r.repeats
#r.repeats += 1
#p r.repeats
#exit


lesspipe(:tail=>true) do |less|
  cluster_lines(lines).each do |cluster|
    less.puts cluster.first.time
    cluster.each { |line| less.puts "\t#{line.text}" }
    less.puts
  end
end
