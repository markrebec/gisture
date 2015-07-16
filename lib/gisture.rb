require 'canfig'
require 'git'
require 'github_api'
require 'gisture/github_api/client/gists'
require 'gisture/version'
require 'gisture/errors'
require 'gisture/evaluator'
require 'gisture/file'
require 'gisture/cloned_file'
require 'gisture/repo_file'
require 'gisture/gist'
require 'gisture/repo'
require 'gisture/repo_gist'
require 'gisture/railtie' if defined?(Rails)

module Gisture
  include Canfig::Module

  configure do |config|
    config.logger         = nil           # defaults to STDOUT but will use Rails.logger in a rails environment
    config.strategy       = :eval         # default execution strategy
    config.tmpdir         = Dir.tmpdir    # location to store gist tempfiles
    config.owners         = nil           # only allow gists/repos/etc. from whitelisted owners (str/sym/arr)

    # config options for the github_api gem
    config.github = Canfig::OpenConfig.new do |github_config|
      github_config.basic_auth     = nil  # user:password string
      github_config.oauth_token    = nil  # oauth authorization token
      github_config.client_id      = nil  # oauth client id
      github_config.client_secret  = nil  # oauth client secret
      github_config.user           = nil  # global user used in requets if none provided
      github_config.org            = nil  # global organization used in request if none provided

      def auth_str
        return "#{oauth_token}:x-oauth-basic" if oauth_token
        return basic_auth if basic_auth
      end
    end

    def whitelisted?(owner)
      owners.nil? || owners.empty? || [owners].flatten.map(&:to_s).include?(owner)
    end
  end

  def self.logger
    configuration.logger || Logger.new(STDOUT)
  end

  def self.new(gist, strategy: nil, filename: nil, version: nil)
    Gisture::Gist.new(gist, strategy: strategy, filename: filename, version: version)
  end

  def self.gist(gist, strategy: nil, filename: nil, version: nil)
    new(gist, strategy: strategy, filename: filename, version: version)
  end

  def self.run(gist, strategy: nil, filename: nil, version: nil, &block)
    new(gist, strategy: strategy, filename: filename, version: version).run!(&block)
  end

  def self.repo(repo)
    Gisture::Repo.new(repo)
  end

  def self.file(path, strategy: nil)
    Gisture::Repo.file(path, strategy: strategy)
  end
end
