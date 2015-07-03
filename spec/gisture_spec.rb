require "spec_helper"

RSpec.describe Gisture do
  describe '.logger' do
    context 'when no logger is configured' do
      it 'returns an instance of the base logger class' do
        expect(Gisture.logger).to be_an_instance_of(Logger)
      end
    end

    context 'when a logger is configured' do
      it 'returns the configured logger' do
        begin
          Gisture.configure do |config|
            config.logger = Logger.new(STDERR)
          end

          expect(Gisture.logger).to eql(Gisture.configuration.logger)
        rescue => e
          raise e
        ensure
          Gisture.configure do |config|
            config.logger = nil
          end
        end
      end
    end
  end

  describe '.new' do
    it 'returns a new Gisture::Gist' do
      expect(Gisture.new(TEST_GIST_ID)).to be_a(Gisture::Gist)
    end

    context 'with arguments' do
      it 'passes the arguments to the gist' do
        gist = Gisture.new(TEST_GIST_ID, filename: TEST_GIST_FILENAME, strategy: :require, version: TEST_GIST_VERSION)
        expect(gist.filename).to eql(TEST_GIST_FILENAME)
        expect(gist.strategy).to eql(:require)
        expect(gist.version).to eql(TEST_GIST_VERSION)
      end
    end
  end

  describe '.gist' do
    it 'returns a new Gisture::Gist' do
      expect(Gisture.gist(TEST_GIST_ID)).to be_a(Gisture::Gist)
    end

    context 'with arguments' do
      it 'passes the arguments to the gist' do
        gist = Gisture.gist(TEST_GIST_ID, filename: TEST_GIST_FILENAME, strategy: :require, version: TEST_GIST_VERSION)
        expect(gist.filename).to eql(TEST_GIST_FILENAME)
        expect(gist.strategy).to eql(:require)
        expect(gist.version).to eql(TEST_GIST_VERSION)
      end
    end
  end

  # TODO should test that the file receives a call to run!
  describe '.run' do
    it 'creates and runs a new Gisture::Gist' do
      expect { Gisture.run(TEST_GIST_ID) }.to_not raise_exception
    end

    context 'with arguments' do
      it 'passes the arguments to the gist' do
        # TODO stub Github::Client::Gists.version
        #expect { Gisture.run(TEST_GIST_ID, filename: TEST_GIST_FILENAME, strategy: :require, version: TEST_GIST_VERSION) }.to_not raise_exception
        expect { Gisture.run(TEST_GIST_ID, filename: TEST_GIST_FILENAME, strategy: :require) }.to_not raise_exception
      end
    end
  end

  describe '.repo' do
    it 'returns a new Gisture::Repo' do
      # TODO stub out Github::Client::Repos
      #expect(Gisture.repo('markrebec/gisture')).to be_a(Gisture::Repo)
    end
  end

  describe '.file' do
    it 'returns a new Gisture::File' do
      # TODO stub out Github::Client::Repos::Contents
      #expect(Gisture.file('https://github.com/markrebec/gisture/blob/master/lib/gisture.rb')).to be_a(Gisture::File)
    end
  end
end
