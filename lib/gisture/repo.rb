module Gisture
  class Repo
    include Cloneable

    attr_reader :owner, :name

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
      @repo ||= github.repos.get user: owner, repo: name
    end

    def file(path, strategy: nil, evaluator: nil, executor: nil)
      if cloned?
        Gisture::File::Cloned.new(clone_path, path, slug: "#{owner}/#{name}", strategy: strategy, evaluator: evaluator, executor: executor)
      else
        file = github.repos.contents.get(user: owner, repo: name, path: path).body
        Gisture::Repo::File.new(file, slug: "#{owner}/#{name}", root: clone_path, strategy: strategy, evaluator: evaluator, executor: executor)
      end
    end

    def files(path)
      if cloned?
        Dir[::File.join(clone_path, path, '*')].map { |f| Hashie::Mash.new({name: ::File.basename(f), path: ::File.join(path, ::File.basename(f))}) }
      else
        github.repos.contents.get(user: owner, repo: name, path: path).body
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

    def clone_url
      "https://#{Gisture.configuration.github.auth_str}@github.com/#{owner}/#{name}.git"
    end

    protected

    def initialize(repo)
      @owner, @name = Gisture.parse_repo_url(repo)
      raise OwnerBlacklisted.new(owner) unless Gisture.configuration.whitelisted?(owner)
    end
  end
end
