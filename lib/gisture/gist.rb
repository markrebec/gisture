module Gisture
  class Gist
    attr_reader :filename, :gist_id, :strategy, :version

    GIST_PATH_REGEX = /\A[a-z0-9_\-]+\/([0-9a-f]{20,20})\/?\Z/
    GIST_URL_REGEX = /\Ahttp.+([0-9a-f]{20,20})\/?\Z/
    GIST_URL_WITH_VERSION_REGEX = /\Ahttp.+([0-9a-f]{20,20})\/([0-9a-f]{40,40})\/?\Z/

    def self.run!(gist, strategy: nil, filename: nil, version: nil, &block)
      new(gist, strategy: strategy, filename: filename, version: version).run!(&block)
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

    def file(fname=nil)
      fname ||= filename
      fname ||= gist.files.first[1].filename
      raise ArgumentError, "The filename '#{fname}' was not found in the list of files for the gist '#{gist_id}'" if gist.files[fname].nil?

      if cloned?
        Gisture::File::Cloned.new(clone_path, fname, basename: "#{owner}/#{gist_id}", strategy: strategy)
      else
        Gisture::File.new(gist.files[fname], basename: "#{owner}/#{gist_id}", strategy: strategy)
      end
    end

    def owner
      gist.owner.login
    end

    def clone_path
      @clone_path ||= ::File.join(Gisture.configuration.tmpdir, owner, gist_id)
    end

    def clone!(&block)
      destroy_clone!
      clone(&block)
    end

    def clone(&block)
      return self if cloned?

      Gisture.logger.info "[gisture] Cloning #{owner}/#{gist_id} into #{clone_path}"

      repo_url = "https://#{Gisture.configuration.github.auth_str}@gist.github.com/#{gist_id}.git"
      Git.clone(repo_url, gist_id, path: ::File.dirname(clone_path))

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
        filename: filename }
    end

    protected

    def initialize(gist, strategy: nil, filename: nil, version: nil)
      self.strategy = strategy || Gisture.configuration.strategy
      @filename = filename

      if gist.match(/[^a-f0-9]+/i) # non-hex chars, probably a URL
        @gist_id, @version = parse_gist_url(gist)
        @version = version unless version.nil?
      else
        @gist_id = gist
        @version = version
      end

    end

    def parse_gist_url(gist_url)
      case gist_url.to_s
      when GIST_URL_WITH_VERSION_REGEX
        matches = gist_url.match(GIST_URL_WITH_VERSION_REGEX)
        return [matches[1], matches[2]]
      when GIST_URL_REGEX
        return [gist_url.match(GIST_URL_REGEX)[1], nil]
      when GIST_PATH_REGEX
        return [gist_url.match(GIST_PATH_REGEX)[1], nil]
      else
        raise ArgumentError, "Invalid argument: #{gist_url} is not a valid gist URL."
      end
    end
  end
end
