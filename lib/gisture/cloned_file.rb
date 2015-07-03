module Gisture
  class ClonedFile < File
    def unlink_tempfile
      false
    end

    protected

    def initialize(filepath, basename: nil, strategy: nil)
      @tempfile = ::File.new(filepath)
      file = Hashie::Mash.new({path: filepath, filename: ::File.basename(filepath), content: tempfile.read})
      super(file, basename: basename, strategy: strategy)
    end
  end
end
