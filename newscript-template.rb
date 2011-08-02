#!/usr/bin/env ruby
require 'epitools'
require 'slop'

opts = Slop.new :help => true do
  banner "Usage: <<scriptname>> -f from -t to [files...]"
  
  on :v, :verbose, 'Enable verbose mode'           
  on :n, :dryrun, 'Dry-run', false                  
  on :f, :from, 'From', :optional => false      
  on :t, :to, 'To', :optional => false  
end


## << One at a time...>>

opts.parse do |arg|
  puts if opts.verbose?
  arg unless opts.dryrun?
end

## << ... or all at once? >>

args = []
opts.parse { |arg| args << arg }

