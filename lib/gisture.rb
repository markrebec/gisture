require 'canfig'
require 'github_api'
require 'gisture/github_api/client/gists'
require 'gisture/version'
require 'gisture/evaluator'
require 'gisture/file'
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

    config.strategy       = :eval       # default execution strategy
    config.tmpdir         = Dir.tmpdir  # location to store gist tempfiles
  end

  def self.new(gist, strategy: nil, filename: nil, version: nil)
    Gisture::Gist.new(gist, strategy: strategy, filename: filename, version: version)
  end

  def self.run(gist, strategy: nil, filename: nil, version: nil, &block)
    new(gist, strategy, filename, version).run!(&block)
  end
end
