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
          result = Gisture.run(gist_url, strategy: strategy, filename: filename)
          if strategy == :exec
            puts result
          else
            result
          end
        end

        protected

        def gist_url
          @gist_url ||= arguments.first.key
        end

        def strategy
          @strategy ||= begin
            strat = arguments.select { |a| a.name == 'strategy' }.first
            if strat.nil?
              strat = 'eval'
            else
              strat = strat.value
            end
            
            if strat == 'eval'
              {eval: evaluator}
            else
              strat.to_sym
            end
          end
        end

        def evaluator
          @evaluator ||= begin
            evlr = arguments.select { |a| a.name == 'evaluator' }.first
            if evlr.nil?
              Gisture::Evaluator
            else
              eval(evlr.value)
            end
          end
        end

        def filename
          @filename ||= begin
            fname = arguments.select { |a| a.name == 'filename' }.first
            if fname.nil?
              fname # nil
            else
              fname.value
            end
          end
        end

      end
    end
  end
end
