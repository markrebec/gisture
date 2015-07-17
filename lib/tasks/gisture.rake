require 'gisture'

namespace :gisture do
  desc 'Run a gist or file in a rake task'
  task :run, [:url, :strategy, :filename, :version, :callback] => :environment do |t,args|
    callback = Proc.new { eval(args.callback.to_s) }
    Gisture.new(args.gist_id, strategy: args.strategy, filename: args.filename, version: args.version).run!(&callback)
  end
end
