module Gisture
  module Strategies
    class Load < Tempfile
      include Include

      def run!(*args, &block)
        include!(:load, *args, &block)
      end
    end
  end
end
