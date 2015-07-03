module Gisture
  class ClonedFile < File
    attr_reader :clone_path

    def require!(&block)
      @cwd = Dir.pwd
      Dir.chdir clone_path
      super
    ensure
      Dir.chdir @cwd
    end

    def load!(&block)
      @cwd = Dir.pwd
      Dir.chdir clone_path
      super
    ensure
      Dir.chdir @cwd
    end

    def eval!(&block)
      @cwd = Dir.pwd
      Dir.chdir clone_path
      super
    ensure
      Dir.chdir @cwd
    end

    def exec!(cmd='ruby', *args, &block)
      @cwd = Dir.pwd
      Dir.chdir clone_path
      super
    ensure
      Dir.chdir @cwd
    end

    def unlink_tempfile
      false
    end

    protected

    def initialize(clone_path, file_path, basename: nil, strategy: nil)
      path = ::File.join(clone_path, file_path)
      @clone_path = clone_path
      @tempfile = ::File.new(path)
      file_hash = Hashie::Mash.new({path: path, filename: ::File.basename(path), content: tempfile.read})
      super(file_hash, basename: basename, strategy: strategy)
    end
  end
end
