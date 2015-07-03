require 'tempfile'

module Gisture
  class File
    attr_reader :file, :basename, :strategy

    STRATEGIES = [:eval, :load, :require]

    def run!(&block)
      send "#{strategy}!".to_sym, &block
    end

    def require!(&block)
      Gisture.logger.info "[gisture] Running #{basename}/#{file.path || file.filename} via the :require strategy"
      required = require tempfile.path
      unlink_tempfile
      block_given? ? yield : required
    end

    def load!(&block)
      Gisture.logger.info "[gisture] Running #{basename}/#{file.path || file.filename} via the :load strategy"
      loaded = load tempfile.path
      unlink_tempfile
      block_given? ? yield : loaded
    end

    def eval!(&block)
      Gisture.logger.info "[gisture] Running #{basename}/#{file.path || file.filename} via the :eval strategy"
      clean_room = Evaluator.new(file.content)
      clean_room.instance_eval &block if block_given?
      clean_room
    end

    def strategy=(strat)
      raise ArgumentError, "Invalid strategy '#{strat}'. Must be one of #{STRATEGIES.join(', ')}" unless STRATEGIES.include?(strat.to_sym)
      @strategy = strat.to_sym
    end

    def tempfile
      @tempfile ||= begin
        tmpfile = Tempfile.new([basename.to_s.gsub(/\//, '-'), file.filename, ::File.extname(file.filename)].compact, Gisture.configuration.tmpdir)
        tmpfile.write(file.content)
        tmpfile.close
        tmpfile
      end
    end

    def unlink_tempfile
      tempfile.unlink
      @tempfile = nil
    end

    def method_missing(meth, *args, &block)
      return file.send(meth, *args, &block) if file.respond_to?(meth)
      super
    end

    def respond_to_missing?(meth, include_private=false)
      file.respond_to?(meth, include_private)
    end

    protected

    def initialize(file, basename: nil, strategy: nil)
      @file = file
      @basename = basename
      self.strategy = strategy || Gisture.configuration.strategy
    end
  end
end
