require 'kommand/commands'

module Gisture
  module Commands
    module Repo
      class Run
        include Kommand::Commands::Command

        command_name 'repo:run'
        command_summary "Run a repo file directly from the command line"
        valid_argument Kommand::Scripts::Argument.new("-f, --filename", summary: "Specify a filename if it's not included in the repo URL")
        valid_argument Kommand::Scripts::Argument.new("-s, --strategy", summary: "Execution strategy, defaults to 'eval'")
        valid_argument Kommand::Scripts::Argument.new("-e, --evaluator", summary: "Use a custom evaluator class, only applies to 'eval' strategy")
        valid_argument Kommand::Scripts::Argument.new("-c, --clone", summary: "Clone the repo into a local tmp path and run from that working dir")
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
          clone? ? repo.clone! : repo.destroy_clone!

          result = file.run!

          if strategy == :exec
            puts result
          else
            result
          end
        end

        protected

        def file
          @file ||= repo.file((repo_url[1] || filename), strategy: strategy)
        end

        def repo
          @repo ||= Gisture.repo(repo_url[0])
        end

        def repo_url
          Gisture::Repo.parse_file_url(arguments.unnamed.first.value)
        rescue
          [Gisture::Repo.parse_repo_url(arguments.unnamed.first.value).join('/')]
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
