
require 'stringio'
require File.dirname(__FILE__) + '/../lib/yahoo_sports'

# if RUBY_PLATFORM =~ /darwin/ and `which tidy` !~ %r{/opt/local} then
if RUBY_PLATFORM =~ /darwin/ then
    # fix for scrapi on Mac OS X
    require "tidy"
    Tidy.path = "/usr/lib/libtidy.dylib"
end

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'minitest/unit'
require 'turn'
require 'turn/reporter'
require 'turn/reporters/outline_reporter'

require "test/test_yahoo_sports"

Turn.config.framework = :minitest
Turn.config.format = :outline

require 'turn/autorun'

MiniTest::Unit.autorun
