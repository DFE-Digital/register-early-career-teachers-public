RSpec.describe SandboxSeedData::Helpers::SchoolURNGenerator, type: :helper do
  before { FactoryBot.create_list(:school, 5) }

  describe ".next" do
    it "produces a new unassigned value" do
      expect(::School.pluck(:urn)).not_to include(described_class.next)
    end

    it "moves the new URN to unavailable" do
      number_of_urns_to_generate = 100
      before_count = described_class.send(:available).count
      number_of_urns_to_generate.times do
        described_class.next
      end
      after_count = described_class.send(:available).count
      expect(before_count - after_count).to eq number_of_urns_to_generate
    end
  end
end
