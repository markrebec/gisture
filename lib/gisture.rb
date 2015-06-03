require 'canfig'
require 'github_api'
require 'gisture/version'
require 'gisture/evaluator'
require 'gisture/gist'

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

  def self.new(gist_id, strategy=:load, filename=nil)
    Gisture::Gist.new(gist_id: gist_id, strategy: strategy, filename: filename)
  end

  def self.run(gist_id, strategy=:load, filename=nil, &block)
    new(gist_id, strategy, filename).run!(&block)
  end
end
