require 'canfig'
require 'git'
require 'github_api'
require 'gisture/github_api/client/gists'
require 'gisture/version'
require 'gisture/errors'
require 'gisture/evaluator'
require 'gisture/file'
require 'gisture/file/cloned'
require 'gisture/gist'
require 'gisture/repo'
require 'gisture/repo/file'
require 'gisture/repo/gist'
require 'gisture/railtie' if defined?(Rails)

module Gisture
  GIST_VERSION_URL_REGEX = /\Ahttp.+([0-9a-f]{20,20})\/([0-9a-f]{40,40})\/?\Z/
  GIST_URL_REGEX = /\Ahttp.+([0-9a-f]{20,20})\/?\Z/
  GIST_PATH_REGEX = /\A[a-z0-9_\-]+\/([0-9a-f]{20,20})\/?\Z/
  GIST_ID_REGEX = /\A([0-9a-f]{20,20})\Z/
  FILE_URL_REGEX = /\A((http[s]?:\/\/)?github\.com\/)?(([a-z0-9_\-\.]+)\/([a-z0-9_\-\.]+))(\/[a-z0-9_\-\.\/]+)\Z/i
  REPO_URL_REGEX = /\A((http[s]?:\/\/)?github\.com\/)?([a-z0-9_\-\.]+)\/([a-z0-9_\-\.]+)\/?\Z/i
  GISTURE_FILE_REGEX = /\A(gisture\.ya?ml|.+\.gist|.+\.gisture)\Z/ # gisture.yml, gisture.yaml, whatever.gist, whatever.gisture

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

  def self.new(url, strategy: nil, filename: nil, version: nil, evaluator: nil, executor: nil)
    case url.to_s
    when GIST_VERSION_URL_REGEX, GIST_URL_REGEX, GIST_PATH_REGEX, GIST_ID_REGEX
      Gisture::Gist.new(url, strategy: strategy, filename: filename, version: version, evaluator: evaluator, executor: executor)
    when FILE_URL_REGEX
      if ::File.basename(url).match(GISTURE_FILE_REGEX)
        Gisture::Repo.gist(url)
      elsif ::File.extname(url).empty?
        Gisture::Repo.gists(url)
      else
        Gisture::Repo.file(url, strategy: strategy, evaluator: evaluator, executor: executor)
      end
    when REPO_URL_REGEX
      Gisture::Repo.new(url)
    else
      raise ArgumentError, "Invalid argument: #{url} does not appear to be a valid gist, repo or file."
    end
  end

  def self.run(url, *args, strategy: nil, filename: nil, version: nil, evaluator: nil, executor: nil, &block)
    new(url, strategy: strategy, filename: filename, version: version, evaluator: evaluator, executor: executor).run!(*args, &block)
  end

  def self.gist(gist, strategy: nil, filename: nil, version: nil, evaluator: nil, executor: nil)
    Gisture::Gist.new(gist, strategy: strategy, filename: filename, version: version, evaluator: evaluator, executor: executor)
  end

  def self.repo(repo)
    Gisture::Repo.new(repo)
  end

  def self.file(path, strategy: nil, evaluator: nil, executor: nil)
    Gisture::Repo.file(path, strategy: strategy, evaluator: evaluator, executor: executor)
  end

  def self.gists(path)
    Gisture::Repo.gists(path)
  end

  def self.parse_repo_url(repo_url)
    raise ArgumentError, "Invalid argument: #{repo_url} does not appear to be a valid repo." unless repo = repo_url.match(REPO_URL_REGEX)
    [repo[3], repo[4]]
  end

  def self.parse_file_url(file_url)
    raise ArgumentError, "Invalid argument: #{file_url} does not appear to be a valid file." unless file = file_url.match(FILE_URL_REGEX)
    [file[3], file[6]]
  end

  def self.parse_gist_url(gist_url)
    case gist_url.to_s
    when GIST_VERSION_URL_REGEX
      matches = gist_url.match(GIST_VERSION_URL_REGEX)
      [matches[1], matches[2]]
    when GIST_URL_REGEX
      [gist_url.match(GIST_URL_REGEX)[1], nil]
    when GIST_PATH_REGEX
      [gist_url.match(GIST_PATH_REGEX)[1], nil]
    when GIST_ID_REGEX
      [gist_url.match(GIST_ID_REGEX)[1], nil]
    else
      raise ArgumentError, "Invalid argument: #{gist_url} does not appear to be a valid gist."
    end
  end
end
