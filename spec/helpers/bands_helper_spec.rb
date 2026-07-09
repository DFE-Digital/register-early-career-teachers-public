describe BandsHelper, type: :helper do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }

  let!(:band_1) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:) }
  let!(:band_2) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:) }

  describe "#label_for" do
    it "returns a label for the band using its letter" do
      expect(label_for(band: band_1)).to eq "Band A"
      expect(label_for(band: band_2)).to eq "Band B"
    end
  end

  describe "#capacity_description_for" do
    it "returns a string with the capacity range for the band" do
      expect(capacity_description_for(band: band_1)).to eq "1 - 100"
      expect(capacity_description_for(band: band_2)).to eq "101 - 200"
    end
  end
end
