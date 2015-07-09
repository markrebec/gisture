require 'github_api/client/gists'
require 'github_api/client/repos'
require 'github_api/client/repos/contents'

module Github
  class Client::Gists < API
    def get_with_vcr(*args)
      arguments(args, required: [:id])

      VCR.use_cassette("gists/#{arguments.id}") do
        get_without_vcr(*args)
      end
    end
    alias_method :get_without_vcr, :get
    alias_method :get, :get_with_vcr
    alias_method :find_without_vcr, :find
    alias_method :find, :get_with_vcr

    def version_with_vcr(*args)
      arguments(args, required: [:id, :version])

      VCR.use_cassette("gists/#{arguments.id}-#{arguments.version}") do
        super
      end
    end
    alias_method :version_without_vcr, :version
    alias_method :version, :version_with_vcr
  end

  class Client::Repos < API
    def get_with_vcr(*args)
      arguments(args, required: [:user, :repo])

      VCR.use_cassette("repos/#{arguments.user}-#{arguments.repo}") do
        get_without_vcr(*args)
      end
    end
    alias_method :get_without_vcr, :get
    alias_method :get, :get_with_vcr
    alias_method :find_without_vcr, :find
    alias_method :find, :get_with_vcr
  end

  class Client::Repos::Contents < API
    def get_with_vcr(*args)
      arguments(args, required: [:user, :repo, :path])

      VCR.use_cassette("repos/#{arguments.user}/#{arguments.repo}/#{arguments.path}") do
        get_without_vcr(*args)
      end
    end
    alias_method :get_without_vcr, :get
    alias_method :get, :get_with_vcr
    alias_method :find_without_vcr, :find
    alias_method :find, :get_with_vcr
  end
end
