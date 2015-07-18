require "spec_helper"

RSpec.describe Gisture::Evaluator do
  it "requires a string to be eval'd" do
    expect { Gisture::Evaluator.new }.to raise_exception(ArgumentError)
  end

  it "converts raw input to a string" do
    expect(Gisture::Evaluator.new(nil).raw).to eql('')
  end

  describe "#raw" do
    subject { Gisture::Evaluator.new("1+1") }

    it "stores the raw string passed on init" do
      expect(subject.raw).to eql("1+1")
    end
  end

  describe "#evaluate" do
    subject { Gisture::Evaluator.new("@raw") }

    it "evaluates the input within the context of the instance" do
      subject.evaluate
      expect(subject.result).to eql("@raw")
    end

    it "returns itself" do
      expect(subject.evaluate).to eql(subject)
    end

    context "when passed a block" do
      it "evaluates the block within the context of the instance" do
        subject.evaluate { @raw = "changed" }
        expect(subject.raw).to eql("changed")
      end
    end
  end

  describe "#result" do
    subject { Gisture::Evaluator.new("1+1") }

    it "stores the result returned by evaluating the block" do
      subject.evaluate
      expect(subject.result).to eql(2)
    end
  end
end
