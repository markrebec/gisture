module Gisture
  class Repo::Gists < Array
    def run!(*args, &block)
      map { |gist| gist.run!(*args, &block) }
    end
  end
end
