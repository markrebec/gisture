require 'canfig'
require 'github_api'
require 'gisture/version'
require 'gisture/evaluator'
require 'gisture/gist'
require 'gisture/railtie' if defined?(Rails)

module Gisture
  include Canfig::Module

  GITHUB_CONFIG_OPTS = [:basic_auth, :oauth_token, :client_id, :client_secret, :user, :org]

  configure do |config|
    # config options for the github_api gem
    config.basic_auth     = nil # user:password string
    config.oauth_token    = nil # oauth authorization token
    config.client_id      = nil # oauth client id
    config.client_secret  = nil # oauth client secret
    config.user           = nil # global user used in requets if none provided
    config.org            = nil # global organization used in request if none provided

    config.tmpdir         = Dir.tmpdir  # location to store gist tempfiles
  end

  def self.new(gist_id, strategy=nil, filename=nil, version=nil)
    if gist_id.match(/[^a-z0-9]+/i) # it's probably a URL
      Gisture::Gist.new(gist_url: gist_id, strategy: strategy, filename: filename, version: version)
    else
      Gisture::Gist.new(gist_id: gist_id, strategy: strategy, filename: filename, version: version)
    end
  end

  def self.run(gist_id, strategy=nil, filename=nil, version=nil, &block)
    new(gist_id, strategy, filename, version).run!(&block)
  end
end
