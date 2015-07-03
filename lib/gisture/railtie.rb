module Gisture
  class Railtie < Rails::Railtie
    initializer "gisture.configure_rails_logger" do
      Gisture.configure do |config|
        config.logger = Rails.logger
      end
    end

    rake_tasks do
      Dir[::File.join(::File.dirname(__FILE__),'../tasks/*.rake')].each { |f| load f }
    end
  end
end
