require 'kommand/cli'
require 'gisture/version'
require 'gisture/commands'

module Gisture
  class CLI < Kommand::CLI
    self.binary = 'gisture'
    self.version = Gisture::VERSION
  end
end
