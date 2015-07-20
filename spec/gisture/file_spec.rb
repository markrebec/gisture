require "spec_helper"

RSpec.describe Gisture::File do
  subject { Gisture::File.new(Gisture::Gist.new(TEST_GIST_ID).gist.files.first[1], slug: TEST_GIST_ID) }

  it "delegates missing methods to the file hash" do
    expect(subject.respond_to?(:content)).to be_true
    expect(subject.respond_to?(:filename)).to be_true
  end
end
