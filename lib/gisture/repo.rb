module Gisture
  class Repo
    attr_reader :owner, :project
    REPO_URL_REGEX = /\A((http[s]?:\/\/)?github\.com\/)?([a-z0-9_\-\.]*)\/([a-z0-9_\-\.]*)\/?\Z/i
    FILE_URL_REGEX = /\A((http[s]?:\/\/)?github\.com\/)?(([a-z0-9_\-\.]*)\/([a-z0-9_\-\.]*))(\/[a-z0-9_\-\.\/]+)\Z/i
    GISTURE_FILE_REGEX = /\A(gisture\.ya?ml|.+\.gist|.+\.gisture)\Z/ # gisture.yml, gisture.yaml, whatever.gist, whatever.gisture

    class << self
      def file(path, strategy: nil)
        repo, file = parse_file_url(path)
        new(repo).file(file, strategy: strategy)
      end

      def run!(path, strategy: nil, &block)
        file(path, strategy: strategy).run!(&block)
      end

      def parse_url(type, url)
        matched = url.match(eval("#{type.to_s.upcase}_URL_REGEX"))
        raise ArgumentError, "Invalid argument: '#{url}' is not a valid #{type.to_s} URL." if matched.nil?
        matched
      end

      def parse_repo_url(repo_url)
        matched = parse_url(:repo, repo_url)
        [matched[3], matched[4]]
      end

      def parse_file_url(file_url)
        matched = parse_url(:file, file_url)
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
        Gisture::File::Cloned.new(clone_path, path, basename: "#{owner}/#{project}", strategy: strategy)
      else
        file = github.repos.contents.get(user: owner, repo: project, path: path).body
        Gisture::Repo::File.new(file, basename: "#{owner}/#{project}", root: clone_path, strategy: strategy)
      end
    end

    def files(path)
      if cloned?
        Dir[::File.join(clone_path, path, '*')].map { |f| Hashie::Mash.new({name: ::File.basename(f), path: ::File.join(path, ::File.basename(f))}) }
      else
        github.repos.contents.get(user: owner, repo: project, path: path).body
      end
    end

    def gists(path)
      if ::File.basename(path).match(GISTURE_FILE_REGEX)
        [Gisture::Repo::Gist.new(self, path)]
      else # must be a directory, look for gists
        files(path).select { |f| f.name.match(GISTURE_FILE_REGEX) }.map { |f| Gisture::Repo::Gist.new(self, f.path) }
      end
    end

    def gist(path)
      gists(path).first
    end

    def run!(path, &block)
      # best guess that it's a gisture file or a directory, otherwise try a file
      if ::File.basename(path).match(GISTURE_FILE_REGEX) || ::File.extname(path).empty?
        gists(path).map { |gist| gist.run!(&block) }
      else
        file(path).run!(&block)
      end
    rescue => e
      Gisture.logger.error "[gisture] #{e.class.name}: #{e.message}\n\t[gisture] #{e.backtrace.join("\n\t[gisture] ")}"
      raise AmbiguousRepoFile, "Don't know how to run '#{path}', try running it as a gist or a file specifically"
    end
    alias_method :run, :run!

    def clone_path
      @clone_path ||= ::File.join(Gisture.configuration.tmpdir, owner, project)
    end

    def clone!(&block)
      destroy_clone!
      clone(&block)
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
