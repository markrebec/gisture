require 'gisture'

namespace :gisture do
  desc 'Run a github gist in a rake task'
  task :run, [:gist_id, :strategy, :filename, :version, :runner] => :environment do |t,args|
    runner = Proc.new { eval(args.runner.to_s) }
    Gisture.run(args.gist_id, strategy: args.strategy, filename: args.filename, version: args.version, &runner)
  end

  namespace :repo do
    desc 'Run a yaml gisture from a github repo in a rake task'
    task :run, [:repo, :yaml_file] => :environment do |t,args|
      Gisture.repo(args.repo).run!(args.yaml_file)
    end

    namespace :file do
      desc 'Run a file from a github repo in a rake task'
      task :run, [:repo, :filename, :strategy, :runner] => :environment do |t,args|
        runner = Proc.new { eval(args.runner.to_s) }
        Gisture.repo(args.repo).file(args.filename, strategy: args.strategy).run!(&runner)
      end
    end
  end
end
