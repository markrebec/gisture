module Gisture
  class Repo
    attr_reader :owner, :project

    class << self
      def file(path, strategy: nil)
        repo, file = Gisture.parse_file_url(path)
        new(repo).file(file, strategy: strategy)
      end

      def gists(path)
        repo, gists = Gisture.parse_file_url(path)
        new(repo).gists(gists)
      end

      def gist(path)
        gists(path).first
      end

      def run!(path, strategy: nil, evaluator: nil, executor: nil, &block)
        file(path, strategy: strategy, evaluator: evaluator, executor: executor).run!(&block)
      end
    end

    def github
      @github ||= Github.new(Gisture.configuration.github.to_h)
    end

    def repo
      @repo ||= github.repos.get user: owner, repo: project
    end

    def file(path, strategy: nil, evaluator: nil, executor: nil)
      if cloned?
        Gisture::File::Cloned.new(clone_path, path, basename: "#{owner}/#{project}", strategy: strategy, evaluator: evaluator, executor: executor)
      else
        file = github.repos.contents.get(user: owner, repo: project, path: path).body
        Gisture::Repo::File.new(file, basename: "#{owner}/#{project}", root: clone_path, strategy: strategy, evaluator: evaluator, executor: executor)
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
      if ::File.basename(path).match(Gisture::GISTURE_FILE_REGEX)
        Gisture::Repo::Gists.new([Gisture::Repo::Gist.load(self, path)])
      else # must be a directory, so let's look for gists
        Gisture::Repo::Gists.new(files(path).select { |f| f.name.match(Gisture::GISTURE_FILE_REGEX) }.map { |f| Gisture::Repo::Gist.load(self, f.path) })
      end
    end

    def gist(path)
      gists(path).first
    end

    def run!(path, *args, strategy: nil, evaluator: nil, executor: nil, &block)
      # best guess that it's a gisture file or a directory, otherwise try a file
      if ::File.basename(path).match(Gisture::GISTURE_FILE_REGEX) || ::File.extname(path).empty?
        gists(path).run!(*args, &block)
      else
        file(path, strategy: strategy, evaluator: evaluator, executor: executor).run!(*args, &block)
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
      @owner, @project = Gisture.parse_repo_url(repo)
      raise OwnerBlacklisted.new(owner) unless Gisture.configuration.whitelisted?(owner)
    end
  end
end
