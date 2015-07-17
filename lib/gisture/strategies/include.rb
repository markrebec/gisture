module Gisture
  module Strategies
    module Include
      def include!(strat, *args, &block)
        log!
        included = eval("#{strat} tempfile.path")
        unlink!
        block_given? ? yield : included
      end
    end
  end
end
