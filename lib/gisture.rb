require 'canfig'
require 'gisture/version'
require 'gisture/gist'

module Gisture
  include Canfig::Module

  configure do |config|
    # config options for the github_api gem
    config.basic_auth     = nil # user:password string
    config.oauth_token    = nil # oauth authorization token
    config.client_id      = nil # oauth client id
    config.client_secret  = nil # oauth client secret
    config.user           = nil # global user used in requets if none provided
    config.org            = nil # global organization used in request if none provided
  end
end
