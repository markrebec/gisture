require 'gisture'

namespace 'gisture' do
  desc 'Run a github gist in a rake task'
  task :run, [:gist_id, :strategy, :filename, :runner] => :environment do |t,args|
    runner = Proc.new { eval(args.runner.to_s) }
    Gisture.run(args.gist_id, args.strategy, args.filename, &runner)
  end
end
