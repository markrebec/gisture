module Gisture
  class Gist
    attr_reader :filename, :gist_id, :strategy, :version

    STRATEGIES = [:eval, :load, :require]
    GIST_URL_REGEX = /\Ahttp.+([0-9a-f]{20,20})\/?\Z/
    GIST_URL_WITH_VERSION_REGEX = /\Ahttp.+([0-9a-f]{20,20})\/([0-9a-f]{40,40})\/?\Z/

    def self.run!(gist, strategy: nil, filename: nil, version: nil, &block)
      new(gist, strategy: strategy, filename: filename, version: version).run!(&block)
    end

    def run!(&block)
      send "#{strategy}!".to_sym, &block
    end

    def require!(&block)
      file.require! &block
    end

    def load!(&block)
      file.load! &block
    end

    def eval!(&block)
      file.eval! &block
    end

    def github
      @github ||= Github.new(Gisture.configuration.github_api)
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

    def file
      @file ||= begin
        if gist.files.count > 1 && !filename.nil?
          raise ArgumentError, "The filename '#{filename}' was not found in the list of files for the gist '#{gist_id}'" if gist.files[filename].nil?
          if cloned?
            Gisture::ClonedFile.new(clone_path, filename, basename: "#{owner}/#{gist_id}", strategy: strategy)
          else
            Gisture::File.new(gist.files[filename], basename: "#{owner}/#{gist_id}", strategy: strategy)
          end
        else
          if cloned?
            Gisture::ClonedFile.new(clone_path, gist.files.first[1].filename, basename: "#{owner}/#{gist_id}", strategy: strategy)
          else
            Gisture::File.new(gist.files.first[1], basename: "#{owner}/#{gist_id}", strategy: strategy)
          end
        end
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
      clone
    end

    def clone(&block)
      return self if cloned?

      Gisture.logger.info "[gisture] Cloning #{owner}/#{gist_id} into #{clone_path}"

      repo_url = "https://#{Gisture.configuration.auth_str}@gist.github.com/#{gist_id}.git"
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
      raise ArgumentError, "Invalid strategy '#{strat}'. Must be one of #{STRATEGIES.join(', ')}" unless STRATEGIES.include?(strat.to_sym)
      @strategy = strat.to_sym
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
      else
        raise ArgumentError, "Invalid argument: #{gist_url} is not a valid gist URL."
      end
    end
  end
end
