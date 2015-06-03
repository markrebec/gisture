require 'tempfile'

module Gisture
  class Gist
    attr_reader :id, :gist, :github, :strategy

    STRATEGIES = [:eval, :load, :require]

    def raw
      gist.files.first[1].content
    end

    def call!(&block)
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

    def strategy=(strat)
      raise ArgumentError, "Invalid strategy '#{strat}'. Must be one of #{STRATEGIES.join(', ')}" unless STRATEGIES.include?(strat.to_sym)
      @strategy = strat.to_sym
    end

    def tempfile
      @tempfile ||= begin
        file = Tempfile.new([id, '.rb'], Gisture.configuration.tmpdir)
        file.write(raw)
        file.close
        file
      end
    end

    protected

    def initialize(gist_id, strategy: :load)
      @id = gist_id
      self.strategy = strategy

      github_config = Gisture::GITHUB_CONFIG_OPTS.map { |key| [key, Gisture.configuration.send(key)] }.to_h
      @github = Github.new(github_config)

      @gist = @github.gists.get(id)
      raise ArgumentError, "Gisture does not currently support gists with more than one file" if gist.files.count > 1
    end

    def unlink_tempfile
      tempfile.unlink
      @tempfile = nil
    end
  end
end
