require 'stringio'
require 'test/unit'
require File.dirname(__FILE__) + '/../lib/yahoo_sports'

require "rubygems"
require "tidy"

if RUBY_PLATFORM =~ /darwin/ then
    # fix for scrapi on Mac OS X
    Tidy.path = "/usr/lib/libtidy.dylib" 
end