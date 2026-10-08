require Rails.root.join("db/scripts/disambiguate_cornwall_districts")

RSpec.describe DisambiguateCornwallDistricts do
  describe "#call" do
    let!(:sw8) { FactoryBot.create(:region, code: "SW8", districts: ["Cornwall", "Isles of Scilly"]) }
    let!(:sw11) { FactoryBot.create(:region, code: "SW11", districts: %w[Cornwall]) }

    it "splits Cornwall into east and west" do
      described_class.new.call

      expect(sw8.reload.districts).to eq(["Cornwall West", "Isles of Scilly"])
      expect(sw11.reload.districts).to eq(["Cornwall East"])
    end
  end
end
