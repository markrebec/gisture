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
      return @file unless @file.nil?

      if gist.files.count > 1 && !filename.nil?
        @file = Gisture::File.new(gist.files[filename], basename: "#{gist.owner.login}/#{gist_id}", strategy: strategy)
        raise ArgumentError, "The filename '#{filename}' was not found in the list of files for the gist '#{gist_id}'" if @file.nil?
      else
        @file = Gisture::File.new(gist.files.first[1], basename: "#{gist.owner.login}/#{gist_id}", strategy: strategy)
      end

      @file
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
