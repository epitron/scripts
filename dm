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

class Line < String

  attr_accessor :secs, :repeats
  
  def initialize(str, secs=0)
    @secs = secs
    @repeats = 1
    super(str)
  end
  
=begin  
  def repeats; @repeats ||= 1; end
  
  def repeats=(val)
    @repeats = val
  end
  
  def secs;       @secs;        end
  def secs=(val); @secs = val;  end
=end

  def time
    Time.at(LAST_REBOOT + @secs)
  end
  
  def merge(other)
    if other == self
      self.repeats += other.repeats
    else
      raise "Can't merge different strings."
    end
  end
  
end

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

def squash_repeats(ss)
  result = []
  
  ss.each do |rs|
    if result.last == rs
      result.last.merge(rs)
    else
      result << rs
    end  
  end
  
  result
end


if $0 == __FILE__
  #lines = Path["~/dmesg.txt"].lines.map do |line|
  
  lines = `dmesg`.lines.map do |line|
    if line =~ /^\[\s*(\d+\.\d+)\] (.+)$/
      Line.new($2, $1.to_f)
    end
  end.compact
  
  p [:lines, lines.size]

  lesspipe(:tail=>true) do |less|
    cluster_lines(lines).each do |chunk|
      less.puts "<9>#{chunk.first.time}".colorize
      squash_repeats(chunk).each do |line|
        less.puts "\t#{line}"
        if line.repeats > 1
          less.puts "\t<8>[...repeated #{line.repeats} times...]".colorize
        end
      end
      less.puts
    end
  end
end  
  

