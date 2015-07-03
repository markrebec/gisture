$:.push File.expand_path("../lib", __FILE__)
require "gisture/version"

Gem::Specification.new do |s|
  s.name        = "gisture"
  s.version     = Gisture::VERSION
  s.summary     = "Execute one-off gists inline or in the background."
  s.description = "Execute one-off gists inline or in the background."
  s.authors     = ["Mark Rebec"]
  s.email       = ["mark@markrebec.com"]
  s.files       = Dir["lib/**/*"]
  s.test_files  = Dir["spec/**/*"]
  s.homepage    = "http://github.com/markrebec/gisture"

  s.add_dependency "canfig"
  s.add_dependency "git"
  s.add_dependency "github_api"

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
end
