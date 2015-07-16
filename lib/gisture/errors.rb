module Gisture
  class OwnerBlacklisted < StandardError
    def initialize(owner)
      super("Gists from '#{owner}' have not been whitelisted for execution. Add them to the 'owners' configuration option.")
    end
  end

  class FileLocalizationError < StandardError; end
  class AmbiguousRepoFile < StandardError; end
end
