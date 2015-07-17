module Gisture
  module Strategies
    class Exec < Tempfile
      attr_reader :executor

      def run!(*args, &block)
        log!

        # set args to the default executor array if none were passed and it exists
        args = executor if args.empty? && executor.is_a?(Array)

        # map nils to file path in args to allow easily inserting the filepath wherever
        # makes sense in your executable arguments (i.e. 'ruby', '-v', nil, '--script-arg')
        args.map! { |arg| arg.nil? ? tempfile.path : arg }

        # attempt to apply a default interpreter if nothing was provided
        # TODO create a legit map of default interpreter args and apply it
        args = ['ruby'] if args.empty? && extname == '.rb'
        args = ['node'] if args.empty? && extname == '.js'

        # append the filepath if it was not inserted into the args already
        args << tempfile.path unless args.include?(tempfile.path)

        # make file executable if we're just invoking it directly
        ::File.chmod(0744, tempfile.path) if args.length == 1

        executed = `#{args.join(' ')}`.strip
        block_given? ? yield : executed
      end

      protected

      def initialize(content, filename: nil, project: nil, executor: nil)
        super(content, project: project, filename: filename)
        @executor = executor
      end
    end
  end
end
