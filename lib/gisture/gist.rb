module Gisture
  class Gist
    attr_reader :filepath, :strategy

    STRATEGIES = [:eval, :load, :require]

    def raw
      File.read(filepath)
    end

    def call!(&block)
      send "#{strategy}!".to_sym, &block
    end

    def require!(&block)
      require filepath
      block.call TOPLEVEL_BINDING if block_given?
    end

    def load!(&block)
      load filepath
      block.call TOPLEVEL_BINDING if block_given?
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

    protected

    def initialize(filepath: nil, strategy: :load)
      @filepath = filepath
      self.strategy = strategy
    end
  end
end
