require "spec_helper"

TEST_GIST_ID = "520b474ea0248d1a0a74"
TEST_GIST_URL = "https://gist.github.com/markrebec/520b474ea0248d1a0a74"
TEST_GIST_VERSION = "49a9d887eeb8c723ab23deddfbbb75d4b70e8014"
TEST_GIST_VERSION_URL = "https://gist.github.com/markrebec/520b474ea0248d1a0a74/49a9d887eeb8c723ab23deddfbbb75d4b70e8014"
TEST_GIST_FILENAME = "test.rb"
MULTI_FILE_TEST_GIST_ID = "0417bf78a7c2b825b4ef"
MULTI_FILE_TEST_GIST_FILENAMES = ['file_one.rb', 'file_two.rb']

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

  describe "#github" do
    subject { Gisture::Gist.new(TEST_GIST_ID) }

    it "is a github_api client object" do
      expect(subject.github).to be_a(Github::Client)
    end
  end

  describe "#gist" do
    subject { Gisture::Gist.new(TEST_GIST_ID) }

    it "is a github_api response" do
      expect(subject.gist).to be_a(Github::ResponseWrapper)
    end

    it "is the gist that was requested" do
      expect(subject.gist.id).to eql(TEST_GIST_ID)
    end
  end

  describe "#gist_file" do
    it "returns an array" do
      expect(Gisture::Gist.new(TEST_GIST_ID).gist_file).to be_a(Array)
    end

    it "contains the filename and file object" do
      gist = Gisture::Gist.new(TEST_GIST_ID)
      expect(gist.gist_file[0]).to eql(TEST_GIST_FILENAME)
      expect(gist.gist_file[1]).to be_a(Hashie::Mash)
    end

    context "when a gist contains a single file" do
      it "returns the file" do
        expect(Gisture::Gist.new(TEST_GIST_ID).gist_file[0]).to eql(TEST_GIST_FILENAME)
      end
    end

    context "when a gist contains more than one file" do
      context "and a filename is present" do
        subject { Gisture::Gist.new(MULTI_FILE_TEST_GIST_ID, filename: MULTI_FILE_TEST_GIST_FILENAMES.sample) }

        it "returns the specified file" do
          expect(subject.gist_file[0]).to eql(subject.filename)
        end
      end

      context "and no filename is present" do
        subject { Gisture::Gist.new(MULTI_FILE_TEST_GIST_ID) }

        it "raises an ArgumentError" do
          expect { subject.gist_file }.to raise_exception(ArgumentError)
        end
      end
    end
  end

  describe "#raw" do
    subject { Gisture::Gist.new(TEST_GIST_ID) }

    it "returns the raw gist content" do
      expect(subject.raw).to eql(subject.gist_file[1].content)
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

  describe "#tempfile" do
    subject { Gisture::Gist.new(TEST_GIST_ID) }

    it "creates and returns a tempfile" do
      expect(subject.tempfile).to be_a(Tempfile)
    end

    it "uses the gist_id as the base of the filename" do
      matched = File.basename(subject.tempfile.path).match(/#{TEST_GIST_ID}/)
      expect(matched).to_not be_nil
    end

    it "uses the same extension as the gist's filename" do
      expect(File.extname(subject.tempfile.path)).to eql(File.extname(subject.gist_file[0]))
    end

    it "creates the file in the configured tempdir" do
      tmp_path = File.join(File.dirname(__FILE__), '../', 'tmp')
      begin
        FileUtils.mkdir_p tmp_path
        Gisture.configure do |config|
          config.tmpdir = tmp_path
        end

        expect(File.dirname(subject.tempfile.path)).to eql(tmp_path)
      rescue => e
        raise e
      ensure
        Gisture.configure do |config|
          config.tmpdir = Dir.tmpdir
        end
        FileUtils.rm_rf tmp_path
      end
    end
  end

  describe "#to_h" do
    subject { Gisture::Gist.new(TEST_GIST_ID, filename: "test.rb") }

    it "returns a hash of the gist attributes" do
      expect(subject.to_h).to eql({gist_id: TEST_GIST_ID, strategy: :eval, filename: "test.rb", version: nil})
    end
  end
end
