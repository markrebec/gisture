module Gisture
  module Strategies
    class Base
      attr_reader :content, :basename, :relpath, :filename, :extname

      def run_from!(path, *args, &block)
        Dir.chdir(path) { run!(*args, &block) }
      end
      alias_method :run_in!, :run_from!

      protected

      def initialize(file, content: nil, basename: nil, filepath: nil, relpath: nil)
        @content = content || file.content
        @basename = basename || file.basename
        @filename = ::File.basename(filename || file.file.filename || file.file.path)
        @extname = ::File.extname(@filename)
        @relpath = relpath || ::File.join(@basename, @filename)
      end

      def klass_name
        self.class.name.split('::').last.downcase
      end

      def log!
        Gisture.logger.info "[gisture] Running #{relpath} from #{Dir.pwd} via the :#{klass_name} strategy"
      end
    end
  end
end
