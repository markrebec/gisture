module Gisture
  module Strategies
    class Base
      attr_reader :content, :project, :relpath, :filename, :extname

      def run_from!(path, *args, &block)
        Dir.chdir(path) { run!(*args, &block) }
      end
      alias_method :run_in!, :run_from!

      protected

      def initialize(content, filename: nil, project: nil, file: nil)
        file ||= Hashie::Mash.new(file: Hashie::Mash.new)
        @content = content || file.content
        @project = project || file.basename || 'gisture/tmp'
        @relpath = filename || ::File.join(@project, (file.file.path || file.file.filename || 'anonymous'))
        @filename = ::File.basename(@relpath)
        @extname = ::File.extname(@filename)
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
