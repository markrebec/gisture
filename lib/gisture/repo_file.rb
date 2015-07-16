module Gisture
  class RepoFile < File
    protected

    def initialize(file, basename: nil, root: nil, strategy: nil)
      file['filename'] = ::File.basename(file['path'])
      file['content'] = Base64.decode64(file['content'])
      super(file, basename: basename, root: root, strategy: strategy)
    end
  end
end
