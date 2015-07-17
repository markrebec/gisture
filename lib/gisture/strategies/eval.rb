module Gisture
  module Strategies
    class Eval < Base
      def run!(*args, &block)
        log!
        evaluator(*args).evaluate(&block)
      end

      def evaluator(*args)
        # push the default evaluator onto args so it gets used if no args were passed
        args << file.evaluator
        klass = eval(args.first.to_s)
        klass.new(file.file.content)
      end
    end
  end
end
