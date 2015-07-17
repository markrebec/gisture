module Gisture
  class Repo::Gist
    attr_reader :repo, :gist

    def self.load(repo, path)
      new(repo, Hashie::Mash.new(YAML.load(repo.file(path).content).symbolize_keys))
    end

    def multi?
      gist.key?(:gistures) || gist.key?(:gists)
    end

    def gists
      # can be a hash of hashes or an array of hashes
      hashes = (gist[:gistures] || gist[:gists] || [])
      hashes = hashes.values if hashes.respond_to?(:values)
      @gists ||= Repo::Gists.new(hashes.map { |mg| self.class.new(repo, mg) })
    end

    def file(file_path, strategy: nil)
      repo.file(file_path, strategy: strategy)
    end

    def runnable
      @runnable ||= file(gist[:path], strategy: gist[:strategy])
    end

    def resources
      @resources ||= (gist[:resources] || []).map { |r| file(r) }
    end

    def clone?
      gist[:clone] == true || !resources.empty?
    end

    def cloned?
      runnable.localized? && resources.all?(&:localized?)
    end

    def clone_path
      repo.clone_path
    end

    def clone!
      resources.each do |resource|
        resource.localize!
      end

      runnable.localize!
    end

    def clone
      resources.each do |resource|
        resource.localize
      end

      runnable.localize
    end

    def destroy_cloned_files!
      resources.each do |resource|
        resource.delocalize!
      end

      runnable.delocalize!
    end

    def run_options
      run_opts = []
      run_opts << eval(gist[:evaluator]) if (!gist.key?(:strategy) || gist[:strategy].to_sym == :eval) && gist.key?(:evaluator)
      run_opts = gist[:executor] if (gist.key?(:strategy) && gist[:strategy].to_sym == :exec) && gist.key?(:executor)
      run_opts
    end

    def run!(*args, &block)
      if multi?
        gists.run!(*args, &block)
      else
        clone!
        chdir_and_run!(*args, &block)
      end
    end

    def chdir_and_run!(*args, &block)
      cwd = Dir.pwd
      Dir.chdir clone_path
      result = runnable.run!(*run_options, &block)
      Dir.chdir cwd
      result
    end

    protected

    def initialize(repo, gist)
      @repo = repo
      @gist = gist
    end
  end
end
