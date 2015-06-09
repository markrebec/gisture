module Github
  class Client::Gists < API
    def get(*args)
      arguments(args, required: [:id])

      TEST_GISTS.to_a.find { |g| g.first == arguments.id }.last
    end

    def version(*args)
      arguments(args, required: [:id, :version])

      # TODO implement this
      nil
    end
  end
end
