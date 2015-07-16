module Gisture
  class File::Cloned < File

    def require!(*args, &block)
      @cwd = Dir.pwd
      Dir.chdir root
      super
    ensure
      Dir.chdir @cwd
    end

    def load!(*args, &block)
      @cwd = Dir.pwd
      Dir.chdir root
      super
    ensure
      Dir.chdir @cwd
    end

    def eval!(*args, &block)
      @cwd = Dir.pwd
      Dir.chdir root
      super
    ensure
      Dir.chdir @cwd
    end

    def exec!(*args, &block)
      @cwd = Dir.pwd
      Dir.chdir root
      super
    ensure
      Dir.chdir @cwd
    end

    def unlink!
      false
    end

    def delocalize!
      false
    end

    protected

    def initialize(clone_path, file_path, basename: nil, strategy: nil)
      path = ::File.join(clone_path, file_path)
      @tempfile = ::File.new(path)
      file_hash = Hashie::Mash.new({path: path, filename: file_path, content: tempfile.read})
      super(file_hash, basename: basename, root: clone_path, strategy: strategy)
    end
  end
end
