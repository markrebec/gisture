require 'tempfile'

module Gisture
  class File
    attr_reader :file, :basename, :root, :strategy

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
      include!(:require, &block)
    end

    def load!(*args, &block)
      include!(:load, &block)
    end

    def eval!(*args, &block)
      Gisture.logger.info "[gisture] Running #{::File.join(basename, (file.filename || file.path))} via the :eval strategy"
      evalor = evaluator(*args)
      evalor.evaluate(&block)
      evalor
    end

    def exec!(*args, &block)
      Gisture.logger.info "[gisture] Running #{::File.join(basename, (file.filename || file.path))} via the :exec strategy"

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
      localize if localized_exists? # just use the localized file if it exists
      @tempfile ||= begin
        tmpfile = Tempfile.new([basename.to_s.gsub(/\//, '-'), file.filename, extname].compact, Gisture.configuration.tmpdir)
        tmpfile.write(file.content)
        tmpfile.close
        tmpfile
      end
    end

    def unlink!
      tempfile.unlink
      @tempfile = nil
    end

    def localized_path
      raise "Cannot localize without a root path" if root.nil?
      ::File.join(root, (file.path || file.filename))
    end

    def exists_locally?
      ::File.exists?(localized_path)
    end

    def localized?
      exists_locally? && localize
    end

    def localize
      if localized?
        @tempfile ||= ::File.new(localized_path)
      else
        localize!
      end
    end

    def localize!
      @tempfile = begin
        Gisture.logger.info "[gisture] Localizing #{file.path || file.filename} into #{root}"
        FileUtils.mkdir_p ::File.dirname(localized_path)
        local_file = ::File.open(localized_path, 'w')
        local_file.write(file.content)
        local_file.close
        local_file
      end
    end

    def delocalize!
      FileUtils.rm_f localized_path
      @tempfile = nil
    end

    def extname
      @extname ||= ::File.extname(file.filename)
    end
    alias_method :extension, :extname

    def method_missing(meth, *args, &block)
      return file.send(meth, *args, &block) if file.respond_to?(meth)
      super
    end

    def respond_to_missing?(meth, include_private=false)
      file.respond_to?(meth, include_private)
    end

    protected

    def initialize(file, basename: nil, root: nil, strategy: nil)
      @file = file
      @basename = basename
      @root = root
      self.strategy = strategy || Gisture.configuration.strategy
    end

    def include!(strat, &block)
      Gisture.logger.info "[gisture] Running #{::File.join(basename, (file.filename || file.path))} via the :#{strat.to_s} strategy"
      included = eval("#{strat} tempfile.path")#load tempfile.path
      unlink!
      block_given? ? yield : included
    end

    def evaluator(*args)
      # push the default evaluator onto args so it gets used if no args were passed
      args << Gisture::Evaluator
      klass = eval(args.first.to_s)
      klass.new(file.content)
    end
  end
end
