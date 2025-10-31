RSpec.describe SandboxSeedData::Helpers::TRNGenerator, type: :helper do
  describe ".next" do
    it "produces new unassigned TRNs every time" do
      1000.times do
        expect(::Teacher.pluck(:trn)).not_to include(described_class.next)
      end
    end
  end
end
