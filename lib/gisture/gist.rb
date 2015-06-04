require 'tempfile'

module Gisture
  class Gist
    attr_reader :filename, :gist_id, :strategy

    STRATEGIES = [:eval, :load, :require]

    def self.run!(gist_id: nil, strategy: nil, filename: nil, &block)
      new(gist_id: gist_id, strategy: strategy, filename: filename).run!(&block)
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
      @gist ||= github.gists.get(gist_id)
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
        strategy: strategy,
        filename: filename }
    end

    protected

    def initialize(gist_id: nil, strategy: nil, filename: nil)
      raise ArgumentError, "Invalid gist_id" if gist_id.nil?
      @gist_id = gist_id
      @filename = filename
      self.strategy = strategy || :eval
    end

    def unlink_tempfile
      tempfile.unlink
      @tempfile = nil
    end
  end
end
