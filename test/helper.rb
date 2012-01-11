require 'rubygems'
require 'bundler/setup'
require 'minitest/spec'
require 'minitest/autorun'
require 'ostruct'

TEST_ROOT = File.expand_path('..', __FILE__)
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

if RUBY_VERSION == '1.8.7'
  class OpenStruct
    undef_method :type
  end
end
