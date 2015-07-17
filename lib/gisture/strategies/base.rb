module Gisture
  module Strategies
    class Base
      attr_reader :file

      def run_from!(path, *args, &block)
        cwd = Dir.pwd
        Dir.chdir path
        result = run!(*args, &block)
        Dir.chdir cwd
        result
      end
      alias_method :run_in!, :run_from!

      protected

      def initialize(file)
        @file = file
      end

      def log!
        Gisture.logger.info "[gisture] Running #{::File.join(file.basename, (file.file.filename || file.file.path))} from #{Dir.pwd} via the :#{self.class.name.split('::').last.downcase} strategy"
      end
    end
  end
end
