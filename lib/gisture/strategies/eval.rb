module Gisture
  module Strategies
    class Eval < Base
      attr_reader :evaluator

      def run!(*args, &block)
        log!
        evalor(*args).evaluate(&block)
      end

      def evalor(*args)
        # push the default evaluator onto args so it gets used if no args were passed
        args << evaluator
        klass = eval(args.first.to_s)
        klass.new(content)
      end

      protected

      def initialize(file, content: nil, basename: nil, filepath: nil, relpath: nil, evaluator: nil)
        @evaluator = evaluator || Gisture::Evaluator
        super(file, content: content, basename: basename, filepath: filepath, relpath: relpath)
      end
    end
  end
end
