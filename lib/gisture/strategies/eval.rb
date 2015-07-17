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

      def initialize(content, filename: nil, project: nil, file: nil, evaluator: nil)
        super(content, project: project, filename: filename, file: file)
        @evaluator = evaluator || Gisture::Evaluator
      end
    end
  end
end
