RSpec.describe APISeedData::Helpers::TRNGenerator, type: :helper do
  describe ".next" do
    it "produces new unassigned TRNs every time" do
      1000.times do
        expect(::Teacher.pluck(:trn)).not_to include(described_class.next)
      end
    end

    # TRNs >= 9_000_000 reserved for induction API testing
    it "only draws from TRNs up to 8,999,999" do
      expect(ALL_TRNS.max).to eq(8_999_999)
    end
  end
end
