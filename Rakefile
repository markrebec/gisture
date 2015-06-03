require 'rspec/core/rake_task'
load 'tasks/gisture.rake'

task :environment do
  # noop
end

desc 'Run the specs'
RSpec::Core::RakeTask.new do |r|
  r.verbose = false
end

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -I lib -r gisture"
end

task :build do
  puts `gem build gisture.gemspec`
end

task :push do
  require 'gisture/version'
  puts `gem push gisture-#{Gisture::VERSION}.gem`
end

task release: [:build, :push] do
  puts `rm -f gisture*.gem`
end

task :default => :spec
