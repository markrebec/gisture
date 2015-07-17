module Gisture
  module Strategies
    class Exec < Base
      def run!(*args, &block)
        log!

        # set args to the default executor array if none were passed and it exists
        args = file.executor if args.empty? && file.executor.is_a?(Array)

        # map nils to file path in args to allow easily inserting the filepath wherever
        # makes sense in your executable arguments (i.e. 'ruby', '-v', nil, '--script-arg')
        args.map! { |arg| arg.nil? ? file.tempfile.path : arg }

        # attempt to apply a default interpreter if nothing was provided
        # TODO create a legit map of default interpreter args and apply it
        args = ['ruby'] if args.empty? && file.extname == '.rb'
        args = ['node'] if args.empty? && file.extname == '.js'

        # append the filepath if it was not inserted into the args already
        args << file.tempfile.path unless args.include?(file.tempfile.path)

        # make file executable if we're just invoking it directly
        ::File.chmod(0744, file.tempfile.path) if args.length == 1

        executed = `#{args.join(' ')}`.strip
        block_given? ? yield : executed
      end
    end
  end
end
