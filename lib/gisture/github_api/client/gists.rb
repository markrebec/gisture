require 'github_api/client/gists'

module Github
  class Client::Gists < API
    def version(*args)
      arguments(args, required: [:id, :version])

      get_request("/gists/#{arguments.id}/#{arguments.version}", arguments.params)
    end
  end
end
