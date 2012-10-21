# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'
require 'jeweler'

Jeweler::Tasks.new do |gemspec|
  gemspec.name = "yahoo_sports19"
  gemspec.summary = "Ruby library for parsing stats from Yahoo! Sports pages"
  gemspec.description = "Ruby library for parsing stats from Yahoo! Sports pages. Currently supports MLB, NBA, NFL and NHL stats and info."
  gemspec.email = "chetan@pixelcop.net"
  gemspec.homepage = "http://github.com/chetan/yahoo_sports"
  gemspec.authors = ["Chetan Sarva"]
end
Jeweler::RubygemsDotOrgTasks.new

require "rake/testtask"
desc "Run unit tests"
Rake::TestTask.new("test") { |t|
    t.libs << 'lib' << 'test'
    t.pattern = "./test/**/*.rb"
    t.verbose = false
    t.warning = false
}

task :default => :test

require "yard"
YARD::Rake::YardocTask.new("docs")
