module Gisture
  class File::Cloned < File

    def unlink!
      false
    end

    def delocalize!
      false
    end

    protected

    def initialize(clone_path, file_path, basename: nil, strategy: nil, evaluator: nil, executor: nil)
      path = ::File.join(clone_path, file_path)
      @localized = ::File.new(path)
      file_hash = Hashie::Mash.new({path: path, filename: file_path, content: localized.read})
      super(file_hash, basename: basename, root: clone_path, strategy: strategy, evaluator: evaluator, executor: executor)
    end
  end
end
