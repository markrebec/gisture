require 'tempfile'

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
      required = require tempfile.path
      unlink_tempfile
      block_given? ? yield : required
    end

    def load!(&block)
      loaded = load tempfile.path
      unlink_tempfile
      block_given? ? yield : loaded
    end

    def eval!(&block)
      clean_room = Evaluator.new(raw)
      clean_room.instance_eval &block if block_given?
      clean_room
    end

    def github
      @github ||= begin
        github_config = Gisture::GITHUB_CONFIG_OPTS.map { |key| [key, Gisture.configuration.send(key)] }.to_h
        Github.new(github_config)
      end
    end

    def gist
      @gist ||= begin
        if @version.nil?
          github.gists.get(gist_id)
        else
          github.gists.version(gist_id, @version)
        end
      end
    end

    def gist_file
      return @gist_file unless @gist_file.nil?

      if gist.files.count > 1
        raise ArgumentError, "You must specify a filename if your gist contains more than one file" if filename.nil?
        gist.files.each do |file|
          @gist_file = file if file[0] == filename
        end
        raise ArgumentError, "The filename '#{filename}' was not found in the list of files for the gist '#{gist_id}'" if @gist_file.nil?
      else
        @gist_file = gist.files.first
      end

      @gist_file
    end

    def raw
      gist_file[1].content
    end

    def strategy=(strat)
      raise ArgumentError, "Invalid strategy '#{strat}'. Must be one of #{STRATEGIES.join(', ')}" unless STRATEGIES.include?(strat.to_sym)
      @strategy = strat.to_sym
    end

    def tempfile
      @tempfile ||= begin
        file = Tempfile.new([gist_id, File.extname(gist_file[0])], Gisture.configuration.tmpdir)
        file.write(raw)
        file.close
        file
      end
    end

    def to_h
      { gist_id: gist_id,
        version: version,
        strategy: strategy,
        filename: filename }
    end

    protected

    def initialize(gist, strategy: nil, filename: nil, version: nil)
      self.strategy = strategy || :eval
      @filename = filename
      @version = version

      if gist.match(/[^a-f0-9]+/i) # non-hex chars, probably a URL
        @gist_id, @version = parse_gist_url(gist)
      else
        @gist_id = gist
      end
    end

    def unlink_tempfile
      tempfile.unlink
      @tempfile = nil
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
