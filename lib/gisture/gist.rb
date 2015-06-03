module Gisture
  class Gist
    # TODO model a gist (the github gist ID, local tempfile, raw data, etc.)
    attr_reader :filepath, :strategy

    def raw
      File.read(filepath)
    end

    def call!(&block)
      send "#{strategy}!".to_sym, &block
    end

    def require!(&block)
      require filepath
      block.call TOPLEVEL_BINDING if block_given?
    end

    def load!(&block)
      load filepath
      block.call TOPLEVEL_BINDING if block_given?
    end

    def eval!(&block)
      clean_room = Evaluator.new(raw)
      clean_room.instance_eval &block if block_given?
      clean_room
    end

    protected

    def initialize(filepath: nil, strategy: :load)
      @filepath = filepath
      @strategy = strategy
    end
  end
end
