require 'tempfile'

module Gisture
  module Strategies
    class Tempfile < Base

      def tempfile_path
        @tempfile.path
      rescue => e
        ::File.join(*[Gisture.configuration.tmpdir, file.basename.to_s.gsub(/\//, '-'), file.file.filename].compact)
      end

      def tempfile
        @tempfile ||= begin
          tmpfile = ::Tempfile.new([file.basename.to_s.gsub(/\//, '-'), file.file.filename, file.extname].compact, Gisture.configuration.tmpdir)
          tmpfile.write(file.file.content)
          tmpfile.close
          tmpfile
        end
      end

      def unlink!
        tempfile.unlink
        @tempfile = nil
      end

      protected

      def initialize(file, tempfile: nil)
        super(file)
        @tempfile = tempfile.is_a?(::File) ? tempfile : ::File.new(tempfile) unless tempfile.nil?
      end
    end
  end
end
