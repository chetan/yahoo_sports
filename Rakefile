require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'
require './lib/yahoo_sports'

Hoe.plugin :newgem
# Hoe.plugin :website
# Hoe.plugin :cucumberfeatures

# Generate all the Rake tasks
# Run 'rake -T' to see list of generated tasks (from gem root directory)
$hoe = Hoe.spec 'yahoo_sports' do
  self.developer 'Chetan Sarva', 'chetan@pixelcop.net'
  self.rubyforge_name       = self.name
  self.extra_deps           = [['scrapi', '>= 1.2.0'],
                               ['tzinfo', '>= 0.3.15']]
end

#require 'newgem/tasks'
#Dir['tasks/**/*.rake'].each { |t| load t }

# TODO - want other tests/tasks run by default? Add them to the list
# remove_task :default
# task :default => [:spec, :features]

desc "Run unit tests"
Rake::TestTask.new("test") { |t|
    #t.libs << "test"
    t.ruby_opts << "-rubygems"
    t.pattern = "test/**/*_test.rb"
    t.verbose = false
    t.warning = false
}