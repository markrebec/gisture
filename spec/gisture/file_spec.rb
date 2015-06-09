require "spec_helper"

RSpec.describe Gisture::File do
  subject { Gisture::File.new(Gisture::Gist.new(TEST_GIST_ID).gist.files.first[1], basename: TEST_GIST_ID) }

  it "delegates missing methods to the file hash" do
    expect(subject.respond_to?(:content)).to be_true
    expect(subject.respond_to?(:filename)).to be_true
  end

  describe "#tempfile" do
    it "creates and returns a tempfile" do
      expect(subject.tempfile).to be_a(Tempfile)
    end

    it "uses the gist_id as the base of the filename" do
      matched = ::File.basename(subject.tempfile.path).match(/#{TEST_GIST_ID}/)
      expect(matched).to_not be_nil
    end

    it "uses the same extension as the gist's filename" do
      expect(::File.extname(subject.tempfile.path)).to eql(::File.extname(subject.file.filename))
    end

    it "creates the file in the configured tempdir" do
      tmp_path = ::File.join(::File.dirname(__FILE__), '../', 'tmp')
      begin
        FileUtils.mkdir_p tmp_path
        Gisture.configure do |config|
          config.tmpdir = tmp_path
        end

        expect(::File.dirname(subject.tempfile.path)).to eql(tmp_path)
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
end
