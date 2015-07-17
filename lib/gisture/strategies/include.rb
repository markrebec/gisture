module Gisture
  module Strategies
    module Include
      def include!(strat, *args, &block)
        log!
        included = eval("#{strat} file.tempfile.path")
        file.unlink!
        block_given? ? yield : included
      end
    end
  end
end
