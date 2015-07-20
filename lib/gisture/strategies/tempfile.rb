require 'tempfile'

module Gisture
  module Strategies
    class Tempfile < Base

      def tempfile
        @tempfile ||= write_tempfile
      end

      def unlink!
        FileUtils.rm_f tempfile.path
        @tempfile = nil
      end

      protected

      def initialize(content, filename: nil, slug: nil, tempfile: nil)
        super(content, slug: slug, filename: filename)
        # allows overriding the tempfile with an existing cloned file path
        @tempfile = tempfile.is_a?(::File) ? tempfile : ::File.new(tempfile) unless tempfile.nil?
      end

      def write_tempfile
        tmpname = [slug.to_s.gsub(/\//, '-'), filename, extname].compact
        tmpfile = ::Tempfile.new(tmpname, Gisture.configuration.tmpdir)
        tmpfile.write(content)
        tmpfile.close
        tmpfile
      end
    end
  end
end
