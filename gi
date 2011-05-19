#!/usr/bin/env ruby
require 'epitools'

REMOTE="epi@ix:git/"


unless ARGV.size == 1 and ARGV.first =~ /^[\w_-]+$/
  
  puts %{
    usage:
      $ gi newproject 
        * creates a new local and remote git repos
          * local: newproject/.git
          * remote: #{REMOTE}newproject.git
  }
  
  exit 1

else
  
  reponame = ARGV.first
  repo = Path[reponame]
  
  raise "local repo (#{repo}) already exists!" if repo.exists?
  
  host, dir = REMOTE.split(':')
  repo_remotedir = "#{dir}#{reponame}.git"
  raise "remote repo (#{host}:#{repo_remotedir}) already exists!" if cmd ["ssh ? ?", host, "test -d #{repo_remotedir}"]
  
  cmd ["git init ?", reponame]
  
  Path.pushd; Path.cd(repo)
  
  cmd ["git remote add origin ?", "#{REMOTE}#{reponame}.git"]
  
  puts
  puts '## First commit!'
  puts
  Path[repo].join("README.md").write("")
  cmd "git add ."
  cmd ["git commit -m ?", "First commit!"]
  
  puts
  puts '## Creating remote repository'
  puts
  cmd ["ssh ? ?", host, "git init --bare #{repo_remotedir}"]
  puts
  puts '## Pushing'
  puts
  cmd "git push origin master"
  
  puts
  puts "##" * 30
  puts "## New Repository: #{reponame}/ => #{host}:#{repo_remotedir}"
  puts "##"
  puts
  
end