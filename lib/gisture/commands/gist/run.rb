require 'kommand/commands'

module Gisture
  module Commands
    module Gist
      class Run
        include Kommand::Commands::Command

        command_name 'gist:run'
        command_summary "Run a gist directly from the command line"
        valid_argument Kommand::Scripts::Argument.new("-f, --filename", summary: "Specify a filename if your gist has multiple files")
        valid_argument Kommand::Scripts::Argument.new("-s, --strategy", summary: "Execution strategy, defaults to 'eval'")
        valid_argument Kommand::Scripts::Argument.new("-e, --evaluator", summary: "Use a custom evaluator class, only applies to 'eval' strategy")
        valid_argument Kommand::Scripts::Argument.new("-c, --clone", summary: "Clone the gist into a local tmp path and run from that working dir")
        validate_arguments false

        class << self
          def usage
            puts "usage: #{Kommand.kommand} #{command_name} GIST_ID_OR_URL #{valid_arguments.to_s}"
            unless valid_arguments.empty?
              puts
              puts "Arguments:"
              puts valid_arguments.to_help
            end
          end
        end

        def run
          clone? ? gist.clone! : gist.destroy_clone!

          result = gist.run!

          if strategy == :exec
            puts result
          else
            result
          end
        end

        protected

        def gist
          @gist = Gisture.gist(gist_url, strategy: strategy, filename: filename)
        end

        def gist_url
          @gist_url ||= arguments.unnamed.first.value
        end

        def strategy
          @strategy ||= begin
            strat = arguments.get(:strategy) || 'eval'
            if strat == 'eval'
              {eval: evaluator}
            else
              strat.to_sym
            end
          end
        end

        def evaluator
          @evaluator ||= eval(arguments.get(:evaluator) || 'Gisture::Evaluator')
        end

        def filename
          @filename ||= arguments.get(:filename)
        end

        def clone?
          arguments.arg?(:clone)
        end

      end
    end
  end
end
