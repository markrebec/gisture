module Gisture
  class Evaluator
    attr_reader :raw, :result

    def evaluate(&block)
      instance_eval { @result = eval raw }
      instance_eval &block if block_given?
      result
    end

    protected
    
    def initialize(raw)
      @raw = raw.to_s
    end
  end
end
