module Gisture
  class Repo::File < File
    protected

    def initialize(file, basename: nil, root: nil, strategy: nil, evaluator: nil, executor: nil)
      file['filename'] = ::File.basename(file['path'])
      file['content'] = Base64.decode64(file['content'])
      super(file, basename: basename, root: root, strategy: strategy, evaluator: evaluator, executor: executor)
    end
  end
end
