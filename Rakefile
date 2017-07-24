# encoding: utf-8

require 'rubygems'
require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rake'

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs      = ["test"]
  t.pattern   = "test/**/test_*.rb"
  t.ruby_opts = ['-w']
end

task :default => :test
