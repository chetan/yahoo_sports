
require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'

Hoe.plugin :newgem

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
Hoe.spec('yahoo_sports') do |s|
  s.version = '0.0.1'
  s.developer('Chetan Sarva', 'chetan@pixelcop.net')
  s.summary = s.description = "Ruby library for parsing stats from Yahoo! Sports pages"
  s.readme_file         = 'README.rdoc'
  s.rubyforge_name      = self.name
  s.extra_deps          = [['scrapi', '>= 1.2.0'],
                           ['tzinfo', '>= 0.3.15']]
end

desc "Run unit tests"
Rake::TestTask.new("test") { |t|
    #t.libs << "test"
    t.ruby_opts << "-rubygems"
    t.pattern = "test/**/*_test.rb"
    t.verbose = false
    t.warning = false
}
