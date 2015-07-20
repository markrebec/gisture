require "spec_helper"

RSpec.describe Gisture::Repo do
  context "when passed a valid repo slug" do
    subject { Gisture::Repo.new('markrebec/gisture') }

    it "sets the owner and project name correctly" do
    end
  end

  context "when passed a valid repo URL" do
    subject { Gisture::Repo.new('https://github.com/markrebec/gisture') }

    it "sets the owner and project name correctly" do
    end
  end

  context "when passed an invalid repo" do
    it "raises an ArgumentError" do
      expect { Gisture::Repo.new('foo') }.to raise_exception(ArgumentError)
      expect { Gisture::Repo.new('markrebec/foo/bar') }.to raise_exception(ArgumentError)
      expect { Gisture::Repo.new('http://github.com') }.to raise_exception(ArgumentError)
    end
  end

  context "when whitelisted owners have been configured" do
    context "and the repo owner is whitelisted" do
      it "does not raise an error" do
        begin
          Gisture.configure do |config|
            config.owners = [:markrebec]
          end

          expect { Gisture::Repo.new('markrebec/gisture') }.to_not raise_exception
        rescue => e
          raise e
        ensure
          Gisture.configure do |config|
            config.owners = nil
          end
        end
      end
    end

    context "and the gist owner is not whitelisted" do
      it "raises a OwnerBlacklisted error" do
        begin
          Gisture.configure do |config|
            config.owners = [:tester]
          end

          expect { Gisture::Repo.new('markrebec/gisture') }.to raise_exception(Gisture::OwnerBlacklisted)
        rescue => e
          raise e
        ensure
          Gisture.configure do |config|
            config.owners = nil
          end
        end
      end
    end
  end

  describe "#github" do
    subject { Gisture::Repo.new('markrebec/gisture') }

    it "is a github_api client object" do
      expect(subject.github).to be_a(Github::Client)
    end
  end

  # TODO stub out Github::Client::Repos
  describe '#repo' do
    context "when the repo doesn't exist" do
    end
  end

  # TODO stub out Github::Client::Repos::Contents
  describe '#file' do
    context "when the repo doesn't exist" do
    end

    context "when the file doesn't exist" do
    end
  end

  describe '.file' do
    context "when the repo doesn't exist" do
    end

    context "when the file doesn't exist" do
    end
  end
end
