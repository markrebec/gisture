module Gisture
  module Strategies
    class Base
      attr_reader :file

      protected

      def initialize(file)
        @file = file
      end

      def log!
        Gisture.logger.info "[gisture] Running #{::File.join(file.basename, (file.file.filename || file.file.path))} via the :#{self.class.name.split('::').last.downcase} strategy"
      end
    end
  end
end
