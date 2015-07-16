module Gisture
  class Repo::Gist
    attr_reader :repo, :path

    def multi?
      gist.key?(:gistures) || gist.key?(:gists)
    end

    def gists
      @gists ||= (gist[:gistures] || gist[:gists] || {}).values.map { |mg| self.class.new(repo, mg) }
    end

    def gist
      @gist ||= Hashie::Mash.new(YAML.load(file(path).content).symbolize_keys)
    end

    def file(file_path, strategy: nil)
      repo.file(file_path, strategy: strategy)
    end

    def runnable
      @runnable ||= file(gist[:path], strategy: gist[:strategy])
    end

    def resources
      @resources ||= gist[:resources].map { |r| file(r) }
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

    def run!(&block)
      if multi?
        gists.map { |gist| gist.run!(&block) }
      else
        run_options = []
        run_options << eval(gist[:evaluator]) if (!gist.key?(:strategy) || gist[:strategy].to_sym == :eval) && gist.key?(:evaluator)
        run_options = gist[:executor] if (gist.key?(:strategy) && gist[:strategy].to_sym == :exec) && gist.key?(:executor)

        clone!
        cwd = Dir.pwd
        Dir.chdir clone_path
        result = runnable.run!(*run_options, &block)
        Dir.chdir cwd
        result
      end
    end

    protected

    def initialize(repo, path)
      @repo = repo
      @path = path
    end
  end
end
