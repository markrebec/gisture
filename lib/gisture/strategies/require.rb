module Gisture
  module Strategies
    class Require < Tempfile
      include Include

      def run!(*args, &block)
        include!(:require, *args, &block)
      end
    end
  end
end
