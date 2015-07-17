require "spec_helper"

RSpec.describe Gisture::Gist do
  context "when passing a gist ID" do
    it "sets the gist ID as the gist_id" do
      expect(Gisture::Gist.new(TEST_GIST_ID).gist_id).to eql(TEST_GIST_ID)
    end

    context "when passing a version" do
      it "sets the version" do
        expect(Gisture::Gist.new(TEST_GIST_ID, version: TEST_GIST_VERSION).version).to eql(TEST_GIST_VERSION)
      end
    end
  end

  context "when passing a gist URL" do
    context "without a version" do
      it "extracts and sets the gist ID as the gist_id" do
        expect(Gisture::Gist.new(TEST_GIST_URL).gist_id).to eql(TEST_GIST_ID)
      end

      context "when passing a version separately" do
        it "sets the version" do
          expect(Gisture::Gist.new(TEST_GIST_URL, version: TEST_GIST_VERSION).version).to eql(TEST_GIST_VERSION)
        end
      end
    end

    context "with a version" do
      it "extracts and sets the gist ID as the gist_id" do
        expect(Gisture::Gist.new(TEST_GIST_VERSION_URL).gist_id).to eql(TEST_GIST_ID)
      end

      it "extracts and sets the gist version as the version" do
        expect(Gisture::Gist.new(TEST_GIST_VERSION_URL).version).to eql(TEST_GIST_VERSION)
      end

      context "when passing a version separately" do
        it "overrides the version with the one explicitly provided" do
          expect(Gisture::Gist.new(TEST_GIST_VERSION_URL, version: "abc123").version).to eql("abc123")
        end
      end
    end
  end

  context "when passing a filename" do
    it "sets the filename" do
      expect(Gisture::Gist.new(TEST_GIST_ID, filename: TEST_GIST_FILENAME).filename).to eql(TEST_GIST_FILENAME)
    end
  end

  context "when passing a strategy" do
    context "which is a valid strategy" do
      it "sets the requested strategy" do
        expect(Gisture::Gist.new(TEST_GIST_ID, strategy: :load).strategy).to eql(:load)
      end
    end

    context "which is not a valid strategy" do
      it "raises an ArgumentError" do
        expect { Gisture::Gist.new(TEST_GIST_ID, strategy: :foo) }.to raise_exception(ArgumentError)
      end
    end
  end

  context "when not passing a strategy" do
    it "uses the default configured strategy" do
      begin
        Gisture.configure do |config|
          config.strategy = :load
        end

        expect(Gisture::Gist.new(TEST_GIST_ID).strategy).to eql(:load)
      rescue => e
        raise e
      ensure
        Gisture.configure do |config|
          config.strategy = :eval
        end
      end
    end
  end

  describe "#github" do
    subject { Gisture::Gist.new(TEST_GIST_ID) }

    it "is a github_api client object" do
      expect(subject.github).to be_a(Github::Client)
    end
  end

  describe "#gist" do
    subject { Gisture::Gist.new(TEST_GIST_ID) }

    it "is the gist that was requested" do
      expect(subject.gist.id).to eql(TEST_GIST_ID)
    end

    context "when whitelisted owners have been configured" do
      context "and the gist owner is whitelisted" do
        it "does not raise an error" do
          begin
            Gisture.configure do |config|
              config.owners = [:markrebec]
            end

            expect { Gisture::Gist.new(TEST_GIST_ID).gist }.to_not raise_exception
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

            expect { Gisture::Gist.new(TEST_GIST_ID).gist }.to raise_exception(Gisture::OwnerBlacklisted)
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
  end

  describe "#file" do
    it "returns a Gisture::File" do
      expect(Gisture::Gist.new(TEST_GIST_ID).file).to be_a(Gisture::File)
    end

    context "when a gist contains a single file" do
      it "returns the file" do
        expect(Gisture::Gist.new(TEST_GIST_ID).file.filename).to eql(TEST_GIST_FILENAME)
      end
    end

    context "when a gist contains more than one file" do
      context "and a filename is present" do
        subject { Gisture::Gist.new(MULTI_FILE_TEST_GIST_ID, filename: MULTI_FILE_TEST_GIST_FILENAMES.sample) }

        it "returns the specified file" do
          expect(subject.file.filename).to eql(subject.filename)
        end
      end

      context "and no filename is present" do
        subject { Gisture::Gist.new(MULTI_FILE_TEST_GIST_ID) }

        it "uses the first file in the gist" do
          expect(subject.file.filename).to eql(MULTI_FILE_TEST_GIST_FILENAMES.first)
        end
      end
    end
  end

  describe "#strategy=" do
    subject { Gisture::Gist.new(TEST_GIST_ID) }

    context "when passed a valid strategy" do
      it "sets the strategy" do
        subject.strategy = :load
        expect(subject.strategy).to eql(:load)
      end
    end

    context "when passed an invalid strategy" do
      it "raises an ArgumentError" do
        expect { subject.strategy = :foo }.to raise_exception(ArgumentError)
      end
    end
  end

  describe "#to_h" do
    subject { Gisture::Gist.new(TEST_GIST_ID, filename: "test.rb") }

    it "returns a hash of the gist attributes" do
      expect(subject.to_h).to eql({gist_id: TEST_GIST_ID, strategy: :eval, filename: "test.rb", version: nil, evaluator: nil, executor: nil})
    end
  end
end
