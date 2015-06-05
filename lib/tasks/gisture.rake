require 'gisture'

namespace 'gisture' do
  desc 'Run a github gist in a rake task'
  task :run, [:gist_id, :strategy, :filename, :version, :runner] => :environment do |t,args|
    runner = Proc.new { eval(args.runner.to_s) }
    Gisture.run(args.gist_id, strategy: args.strategy, filename: args.filename, version: args.version, &runner)
  end
end
