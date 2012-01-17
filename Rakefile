# encoding: utf-8

require 'rubygems'
require 'bundler/setup'
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "lolsoap"
  gem.homepage = "http://github.com/loco2/lolsoap"
  gem.license = "MIT"
  gem.summary = %Q{A library for dealing with SOAP requests and responses.}
  gem.description = %Q{A library for dealing with SOAP requests and responses. We tear our hair out so you don't have to.}
  gem.email = "j@jonathanleighton.com"
  gem.authors = ["Jon Leighton"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs      = ["test"]
  t.pattern   = "test/**/test_*.rb"
  t.ruby_opts = ['-w']
end

task :default => :test
