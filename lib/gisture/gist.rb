require 'tempfile'

module Gisture
  class Gist
    attr_reader :filename, :gist_id, :strategy, :version

    STRATEGIES = [:eval, :load, :require]
    GIST_ID_REGEX = /\A[0-9a-f]{20,20}\Z/
    GIST_URL_REGEX = /\Ahttp.+([0-9a-f]{20,20})\/?\Z/
    GIST_URL_WITH_VERSION_REGEX = /\Ahttp.+([0-9a-f]{20,20})\/([0-9a-f]{40,40})\/?\Z/

    class << self
      def run!(gist_id: nil, strategy: nil, filename: nil, version: nil, &block)
        new(gist_id: gist_id, strategy: strategy, filename: filename, version: version).run!(&block)
      end

      def parse_gist_url(gist_url)
        case gist_url.to_s
        when GIST_URL_WITH_VERSION_REGEX
          return [gist_url.match(GIST_URL_WITH_VERSION_REGEX)[1], gist_url.match(GIST_URL_WITH_VERSION_REGEX)[2]]
        when GIST_URL_REGEX
          return [gist_url.match(GIST_URL_REGEX)[1], nil]
        else
          raise ArgumentError, "Invalid argument: #{gist_url} is not a valid gist URL."
        end
      end

      def parse_gist_id(gist_id)
        gist_id = gist_id.to_s
        case gist_id.to_s
        when GIST_ID_REGEX
          gist_id
        when GIST_URL_WITH_VERSION_REGEX
          gist_id.match(GIST_URL_WITH_VERSION_REGEX)[1]
        when GIST_URL_REGEX
          gist_id.match(GIST_URL_REGEX)[1]
        else
          raise ArgumentError, "Invalid argument: #{gist_id} is not a gist_id or a gist's URL."
        end
      end

      def parse_version(gist_id: gist_id, version: nil)
        match = gist_id.match(GIST_URL_WITH_VERSION_REGEX)
        if match && version
          raise ArgumentError, "You are trying to specify a gist version in both your URL (#{gist_id}) and your version argument (#{version})."
        elsif match
          match[2]
        else
          version
        end
      end
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

    # TODO refactor to initialize(gist_id_or_url, strategy: nil, filename: nil, version: nil)
    def initialize(gist_id: nil, gist_url: nil, strategy: nil, filename: nil, version: nil)
      @filename = filename
      if !gist_id.nil?
        @gist_id = gist_id
        @version = version
      elsif !gist_url.nil?
        @gist_id, @version = self.class.parse_gist_url(gist_url)
      else
        raise ArgumentError, "You must provide one of gist_id or gist_url"
      end
      self.strategy = strategy || :eval
    end

    def unlink_tempfile
      tempfile.unlink
      @tempfile = nil
    end
  end
end
