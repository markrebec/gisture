require 'kommand/commands'

module Gisture
  module Commands
    module Repo
      class Run
        include Kommand::Commands::Command

        command_name 'repo:run'
        command_summary "Run a yaml gisture directly from the command line"
        validate_arguments false

        class << self
          def usage
            puts "usage: #{Kommand.kommand} #{command_name} YAML_GISTURE_URL #{valid_arguments.to_s}"
            unless valid_arguments.empty?
              puts
              puts "Arguments:"
              puts valid_arguments.to_help
            end
          end
        end

        def run
          repo.run!(repo_url[1])
        end

        protected


        def repo
          @repo ||= Gisture.repo(repo_url[0])
        end

        def repo_url
          Gisture::Repo.parse_file_url(arguments.unnamed.first.value)
        rescue
          [Gisture::Repo.parse_repo_url(arguments.unnamed.first.value).join('/')]
        end

      end
    end
  end
end
