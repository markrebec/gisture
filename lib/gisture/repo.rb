module Gisture
  class Repo
    attr_reader :owner, :project
    REPO_URL_REGEX = /\A((http[s]?:\/\/)?github\.com\/)?([a-z0-9_\-\.]*)\/([a-z0-9_\-\.]*)\/?\Z/i
    FILE_URL_REGEX = /\A((http[s]?:\/\/)?github\.com\/)?(([a-z0-9_\-\.]*)\/([a-z0-9_\-\.]*))(\/[a-z0-9_\-\.\/]+)\Z/i

    class << self
      def file(path, strategy: nil)
        repo, file = parse_file_url(path)
        new(repo).file(file, strategy: strategy)
      end

      def run!(path, strategy: nil, &block)
        file(path, strategy: strategy).run!(&block)
      end

      def parse_repo_url(repo_url)
        matched = repo_url.match(REPO_URL_REGEX)
        raise ArgumentError, "Invalid argument: '#{repo_url}' is not a valid repo URL." if matched.nil?
        [matched[3], matched[4]]
      end

      def parse_file_url(file_url)
        matched = file_url.match(FILE_URL_REGEX)
        raise ArgumentError, "Invalid argument: '#{file_url}' is not a valid file path." if matched.nil?
        [matched[3], matched[6]]
      end
    end

    def github
      @github ||= Github.new(Gisture.configuration.github.to_h)
    end

    def repo
      @repo ||= github.repos.get user: owner, repo: project
    end

    def file(path, strategy: nil)
      if cloned?
        Gisture::ClonedFile.new(clone_path, path, basename: "#{owner}/#{project}", strategy: strategy)
      else
        file = github.repos.contents.get(user: owner, repo: project, path: path).body
        Gisture::RepoFile.new(file, basename: "#{owner}/#{project}", strategy: strategy)
      end
    end

    def run!(path, strategy: nil, &block)
      file(path, strategy: strategy).run!(&block)
    end

    def clone_path
      @clone_path ||= ::File.join(Gisture.configuration.tmpdir, owner, project)
    end

    def clone!(&block)
      destroy_clone!
      clone
    end

    def clone(&block)
      return self if cloned?

      Gisture.logger.info "[gisture] Cloning #{owner}/#{project} into #{clone_path}"

      repo_url = "https://#{Gisture.configuration.github.auth_str}@github.com/#{owner}/#{project}.git"
      Git.clone(repo_url, project, path: ::File.dirname(clone_path))

      FileUtils.rm_rf("#{clone_path}/.git")
      ::File.write("#{clone_path}/.gisture", Time.now.to_i.to_s)

      if block_given?
        instance_eval &block
        destroy_clone!
      end

      self
    end

    def destroy_clone!
      FileUtils.rm_rf(clone_path)
    end

    def cloned?
      ::File.read("#{clone_path}/.gisture").strip
    rescue
      false
    end

    protected

    def initialize(repo)
      @owner, @project = self.class.parse_repo_url(repo)
      raise OwnerBlacklisted.new(owner) unless Gisture.configuration.whitelisted?(owner)
    end
  end
end
