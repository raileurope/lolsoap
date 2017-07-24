# encoding: utf-8

require 'rubygems'
require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rake'

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = Dir.glob('test/**/test_*.rb').shuffle
  t.verbose = false
  t.warning = true
end

task default: :test
