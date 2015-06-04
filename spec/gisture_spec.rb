require "spec_helper"

RSpec.describe Gisture do
  describe "testing various inputs" do
    SAMPLE_GIST_ID = "c3b478ef0592eacad361".freeze
    SAMPLE_GIST_VERSION = "7714df11a3babaa78f27027844ac2f0c1a8348c1".freeze
    SAMPLE_GIST_URL = "https://gist.github.com/markrebec/#{SAMPLE_GIST_ID}".freeze
    SAMPLE_GIST_URL_WITH_VERSION = "https://gist.github.com/markrebec/#{SAMPLE_GIST_ID}/#{SAMPLE_GIST_VERSION}".freeze
    DEFAULT_NEW_GIST_ARGS = {gist_id: nil, strategy: nil, filename: nil, version: nil}

    it "throws an error with missing input" do
      expect { Gisture::Gist.parse_gist_id() }.
        to raise_error(ArgumentError)
    end

    describe "passed a string" do

      it "works with a gist ID" do
        expect(Gisture::Gist.parse_gist_id(SAMPLE_GIST_ID)).
          to eq(SAMPLE_GIST_ID)
      end

      it "works with a gist ID and a version parameter" do
        expect(Gisture::Gist.parse_gist_id(SAMPLE_GIST_ID)).
          to eq(SAMPLE_GIST_ID)
        expect(Gisture::Gist.
                parse_version(gist_id: SAMPLE_GIST_ID,
                              version: SAMPLE_GIST_VERSION)).
          to eq(SAMPLE_GIST_VERSION)
      end

      it "throws an error with a bad string" do
        expect { Gisture::Gist.parse_gist_id('123') }.
          to raise_error(ArgumentError)
      end
    end

    describe "passed a non-string" do
      it "converts a valid non-string" do
        expect(Gisture::Gist.parse_gist_id(SAMPLE_GIST_ID.to_sym)).
          to eq(SAMPLE_GIST_ID)
      end

      it "throws an error with a bad non-string" do
        expect { Gisture::Gist.parse_gist_id(123) }.
          to raise_error(ArgumentError)
      end
    end

    describe "takes a gist URL as input, with a gist ID and" do
      it "without a version" do
        expect(Gisture::Gist.parse_gist_id(SAMPLE_GIST_URL)).
          to eq(SAMPLE_GIST_ID)
      end

      it "with a version" do
        expect(Gisture::Gist.parse_gist_id(SAMPLE_GIST_URL_WITH_VERSION)).
          to eq(SAMPLE_GIST_ID)
        expect(Gisture::Gist.
                parse_version(gist_id: SAMPLE_GIST_URL_WITH_VERSION)).
          to eq(SAMPLE_GIST_VERSION)
      end

      it "throws an error with differing versions" do
        expect { Gisture::Gist.
                 parse_version(gist_id: SAMPLE_GIST_URL_WITH_VERSION,
                               version: SAMPLE_GIST_VERSION) }.
          to raise_error(ArgumentError)
      end
    end
  end
end
