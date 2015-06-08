module Gisture
  class Evaluator
    attr_reader :raw, :result

    def evaluate
      instance_eval { @result = eval raw }
    end

    protected
    
    def initialize(raw)
      @raw = raw.to_s
      evaluate
    end
  end
end
