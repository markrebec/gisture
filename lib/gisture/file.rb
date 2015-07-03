require 'tempfile'

module Gisture
  class File
    attr_reader :file, :basename, :strategy

    STRATEGIES = [:eval, :exec, :load, :require]

    def run!(*args, &block)
      strat_key = strategy
      if strategy.respond_to?(:keys)
        strat_key = strategy.keys.first
        if strategy[strat_key].is_a?(Array)
          args = args.concat(strategy[strat_key])
        else
          args << strategy[strat_key]
        end
      end

      send "#{strat_key}!".to_sym, *args, &block
    end

    def require!(*args, &block)
      Gisture.logger.info "[gisture] Running #{basename}/#{file.path || file.filename} via the :require strategy"
      required = require tempfile.path
      unlink_tempfile
      block_given? ? yield : required
    end

    def load!(*args, &block)
      Gisture.logger.info "[gisture] Running #{basename}/#{file.path || file.filename} via the :load strategy"
      loaded = load tempfile.path
      unlink_tempfile
      block_given? ? yield : loaded
    end

    def eval!(*args, &block)
      Gisture.logger.info "[gisture] Running #{basename}/#{file.path || file.filename} via the :eval strategy"
      args << Gisture::Evaluator
      klass = args.first
      evaluator = klass.new(file.content)
      evaluator.instance_eval &block if block_given?
      evaluator
    end

    def exec!(*args, &block)
      Gisture.logger.info "[gisture] Running #{basename}/#{file.path || file.filename} via the :exec strategy"

      # map nils to file path in args to allow easily inserting the filepath wherever
      # makes sense in your executable arguments (i.e. 'ruby', '-v', nil, '--script-arg')
      args.map! { |arg| arg.nil? ? tempfile.path : arg }

      # attempt to apply a default interpreter if nothing was provided
      # TODO create a legit map of default interpreter args and apply it
      args = ['ruby'] if args.empty? && extname == '.rb'
      args = ['node'] if args.empty? && extname == '.js'

      # append the filepath if it was not inserted into the args already
      args << tempfile.path unless args.include?(tempfile.path)

      # make file executable if we're just invoking it directly
      ::File.chmod(0744, tempfile.path) if args.length == 1

      executed = `#{args.join(' ')}`.strip
      block_given? ? yield : executed
    end

    def strategy=(strat)
      strat_key = strat
      strat_key = strat.keys.first if strat.respond_to?(:keys)
      raise ArgumentError, "Invalid strategy '#{strat_key}'. Must be one of #{STRATEGIES.join(', ')}" unless STRATEGIES.include?(strat_key.to_sym)
      @strategy = strat
    end

    def tempfile
      @tempfile ||= begin
        tmpfile = Tempfile.new([basename.to_s.gsub(/\//, '-'), file.filename, extname].compact, Gisture.configuration.tmpdir)
        tmpfile.write(file.content)
        tmpfile.close
        tmpfile
      end
    end

    def extname
      @extname ||= ::File.extname(file.filename)
    end
    alias_method :extension, :extname

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
