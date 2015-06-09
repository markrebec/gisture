module Gisture
  class Repo
    attr_reader :owner, :project
    REPO_URL_REGEX = /\A((http[s]?:\/\/)?github\.com\/)?([a-z0-9_-]*)\/([a-z0-9_-]*)\/?\Z/

    def github
      @github ||= begin
        Github.new(github_config)
      end
    end

    def repo
      @repo ||= github.repos.get user: owner, repo: project
    end

    def file(path, strategy: nil)
      file = github.repos.contents.get(user: owner, repo: project, path: path).body
      file['filename'] = ::File.basename(file['path'])
      file['content'] = Base64.decode64(file['content'])
      Gisture::File.new(file, basename: "#{owner}-#{project}", strategy: strategy)
    end

    protected

    def initialize(repo)
      @owner, @project = parse_repo_url(repo)
    end

    def parse_repo_url(repo_url)
      matched = repo_url.match(REPO_URL_REGEX)
      raise ArgumentError, "Invalid argument: '#{repo_url}' is not a valid repo URL." if matched.nil?
      [matched[3], matched[4]]
    end

    def github_config
      github_config = Hash[Gisture::GITHUB_CONFIG_OPTS.map { |key| [key, Gisture.configuration.send(key)] }]
    end
  end
end
