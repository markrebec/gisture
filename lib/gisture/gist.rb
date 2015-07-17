module Gisture
  class Gist
    attr_reader :evaluator, :executor, :filename, :gist_id, :strategy, :version

    def self.run!(gist, *args, strategy: nil, filename: nil, version: nil, evaluator: nil, executor: nil, &block)
      new(gist, strategy: strategy, filename: filename, version: version, evaluator: nil, executor: nil).run!(*args, &block)
    end

    def run!(*args, &block)
      file.run! *args, &block
    end

    def require!(*args, &block)
      file.require! *args, &block
    end

    def load!(*args, &block)
      file.load! *args, &block
    end

    def eval!(*args, &block)
      file.eval! *args, &block
    end

    def exec!(*args, &block)
      file.exec! *args, &block
    end

    def github
      @github ||= Github.new(Gisture.configuration.github.to_h)
    end

    def gist
      @gist ||= begin
        if @version.nil?
          g = github.gists.get(gist_id)
        else
          g = github.gists.version(gist_id, @version)
        end
        raise OwnerBlacklisted.new(g.owner.login) unless Gisture.configuration.whitelisted?(g.owner.login)
        g
      end
    end

    def file_exists?(fname)
      !gist.files[fname].nil?
    end

    def file(fname=nil)
      fname ||= (filename || gist.files.first[1].filename)
      raise ArgumentError, "The filename '#{fname}' was not found in the list of files for the gist '#{gist_id}'" unless file_exists?(fname)

      if cloned?
        Gisture::File::Cloned.new(clone_path, fname, basename: "#{owner}/#{gist_id}", strategy: strategy, evaluator: evaluator, executor: executor)
      else
        Gisture::File.new(gist.files[fname], basename: "#{owner}/#{gist_id}", strategy: strategy, evaluator: evaluator, executor: executor)
      end
    end

    def owner
      gist.owner.login
    end

    def clone_path
      @clone_path ||= ::File.join(Gisture.configuration.tmpdir, owner, gist_id)
    end

    def clone_url
      @clone_url ||= "https://#{Gisture.configuration.github.auth_str}@gist.github.com/#{gist_id}.git"
    end

    def clone!(&block)
      destroy_clone!
      clone(&block)
    end

    def clone(&block)
      return self if cloned?

      Gisture.logger.info "[gisture] Cloning #{owner}/#{gist_id} into #{clone_path}"
      Git.clone(clone_url, gist_id, path: ::File.dirname(clone_path))
      stamp_clone!

      if block_given?
        instance_eval &block
        destroy_clone!
      end

      self
    end

    # removes the .git path and adds a .gisture stamp
    def stamp_clone!
      FileUtils.rm_rf("#{clone_path}/.git")
      ::File.write("#{clone_path}/.gisture", Time.now.to_i.to_s)
    end

    def destroy_cloned_files!
      FileUtils.rm_rf(clone_path)
    end
    alias_method :destroy_clone!, :destroy_cloned_files!

    def cloned?
      ::File.read("#{clone_path}/.gisture").strip
    rescue
      false
    end

    def strategy=(strat)
      strat_key = strat
      strat_key = strat.keys.first if strat.respond_to?(:keys)
      raise ArgumentError, "Invalid strategy '#{strat_key}'. Must be one of #{File::STRATEGIES.join(', ')}" unless File::STRATEGIES.include?(strat_key.to_sym)
      @strategy = strat
    end

    def to_h
      { gist_id: gist_id,
        version: version,
        strategy: strategy,
        filename: filename,
        evaluator: evaluator,
        executor: executor }
    end

    protected

    def initialize(gist, strategy: nil, filename: nil, version: nil, evaluator: nil, executor: nil)
      gist_id, gist_version = Gisture.parse_gist_url(gist)
      @gist_id = gist_id
      @version = (version || gist_version)
      @filename = filename
      @evaluator = evaluator
      @executor = executor
      self.strategy = strategy || Gisture.configuration.strategy
    end
  end
end
