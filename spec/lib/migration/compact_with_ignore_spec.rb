class SomeExample
  def a_hash
    { a: 1, b: nil, c: :ignore }
  end
end

describe "Migration::CompactWithIgnore" do
  using Migration::CompactWithIgnore

  subject { SomeExample.new.a_hash }

  describe "#compact_with_ignore" do
    it "compacts the hash" do
      expect(subject.compact_with_ignore.key?(:b)).to be(false)
    end

    it "converts :ignore to nil" do
      expect(subject.compact_with_ignore.fetch(:c)).to be_nil
    end

    it "doesn't overwrite the original hash" do
      subject.compact_with_ignore

      expect(subject).to eql({ a: 1, b: nil, c: :ignore })
    end
  end

  describe "#compact_with_ignore!" do
    it "overwrites the original hash" do
      subject.compact_with_ignore!

      expect(subject).to eql({ a: 1, c: nil })
    end
  end
end
