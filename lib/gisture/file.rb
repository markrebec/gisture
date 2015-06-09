require 'tempfile'

module Gisture
  class File
    attr_reader :file, :basename

    def require!(&block)
      required = require tempfile.path
      unlink_tempfile
      block_given? ? yield : required
    end

    def load!(&block)
      loaded = load tempfile.path
      unlink_tempfile
      block_given? ? yield : loaded
    end

    def eval!(&block)
      clean_room = Evaluator.new(content)
      clean_room.instance_eval &block if block_given?
      clean_room
    end

    def tempfile
      @tempfile ||= begin
        file = Tempfile.new([basename, filename, ::File.extname(filename)].compact, Gisture.configuration.tmpdir)
        file.write(content)
        file.close
        file
      end
    end

    def unlink_tempfile
      tempfile.unlink
      @tempfile = nil
    end

    def method_missing(meth, *args, &block)
      return file.send(meth, *args, &block) if file.respond_to?(meth)
      super
    end

    def respond_to_missing?(meth, include_private=false)
      file.respond_to?(meth, include_private)
    end

    protected

    def initialize(file, basename=nil)
      @file = file
      @basename = basename
    end
  end
end
