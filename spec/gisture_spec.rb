require "spec_helper"

RSpec.describe Gisture do
  SAMPLE_GIST_ID = "c3b478ef0592eacad361".freeze
  SAMPLE_GIST_VERSION = "7714df11a3babaa78f27027844ac2f0c1a8348c1".freeze
  SAMPLE_GIST_URL = "https://gist.github.com/markrebec/#{SAMPLE_GIST_ID}".freeze
  SAMPLE_GIST_URL_WITH_VERSION = "https://gist.github.com/markrebec/#{SAMPLE_GIST_ID}/#{SAMPLE_GIST_VERSION}".freeze
end
