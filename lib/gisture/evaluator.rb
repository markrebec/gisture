module Gisture
  class Evaluator
    attr_reader :raw

    protected
    
    def initialize(raw)
      @raw = raw
      instance_eval { eval raw }
    end
  end
end
