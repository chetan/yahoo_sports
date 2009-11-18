require 'stringio'
require 'test/unit'
require File.dirname(__FILE__) + '/../lib/yahoo_sports'

begin; require "turn"; rescue LoadError; end

if RUBY_PLATFORM =~ /darwin/ then
    # fix for scrapi on Mac OS X
    require "rubygems"
    require "tidy"
    Tidy.path = "/usr/lib/libtidy.dylib" 
end