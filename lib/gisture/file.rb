module Gisture
  class File
    attr_reader :evaluator, :executor, :file, :basename, :root, :localized, :strategy

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

    # TODO rework these to use .run_from!(root) if file is cloned/localized
    def eval!(*args, &block)
      Strategies::Eval.new(content, filename: relative_path, project: basename).run!(*args, &block)
    end

    def exec!(*args, &block)
      Strategies::Exec.new(content, filename: relative_path, project: basename, tempfile: @localized).run!(*args, &block)
    end

    def require!(*args, &block)
      Strategies::Require.new(content, filename: relative_path, project: basename, tempfile: @localized).run!(*args, &block)
    end

    def load!(*args, &block)
      Strategies::Load.new(content, filename: relative_path, project: basename, tempfile: @localized).run!(*args, &block)
    end

    def relative_path
      file.path || file.filename
    end

    def strategy=(strat)
      strat_key = strat
      strat_key = strat.keys.first if strat.respond_to?(:keys)
      raise ArgumentError, "Invalid strategy '#{strat_key}'. Must be one of #{STRATEGIES.join(', ')}" unless STRATEGIES.include?(strat_key.to_sym)
      @strategy = strat
    end

    def localized_path
      ::File.join(root, (file.path || file.filename))
    rescue => e
      nil.to_s
    end

    def exists_locally?
      ::File.exists?(localized_path)
    end

    def localized?
      exists_locally? && localize
    end

    def localize
      if localized?
        @localized ||= ::File.new(localized_path)
      else
        localize!
      end
    end

    def localize!
      raise FileLocalizationError, "Cannot localize without a :root path" if root.nil?
      @localized = begin
        Gisture.logger.info "[gisture] Localizing #{file.path || file.filename} into #{root}"
        FileUtils.mkdir_p ::File.dirname(localized_path)
        localize_file!
      end
    end

    def localize_file!
      local_file = ::File.open(localized_path, 'w')
      local_file.write(file.content)
      local_file.close
      local_file
    end

    def delocalize!
      FileUtils.rm_f localized_path
      @localized = nil
    end
    alias_method :unlink!, :delocalize!

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

    def initialize(file, basename: nil, root: nil, strategy: nil, evaluator: nil, executor: nil)
      @file = file
      @basename = basename
      @root = root
      @evaluator = evaluator || Gisture::Evaluator
      @executor = executor
      self.strategy = strategy || Gisture.configuration.strategy
    end
  end
end
