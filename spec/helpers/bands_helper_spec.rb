describe BandsHelper, type: :helper do
  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:) }

  let!(:band_1) { FactoryBot.create(:framework_agreement_band, framework_agreement:) }
  let!(:band_2) { FactoryBot.create(:framework_agreement_band, framework_agreement:) }

  describe "#band_label" do
    it "returns a label for the band using its letter" do
      expect(band_label(band: band_1)).to eq "Band A"
      expect(band_label(band: band_2)).to eq "Band B"
    end
  end

  describe "#band_capacity_description" do
    it "returns a string with the capacity range for the band" do
      expect(band_capacity_description(band: band_1)).to eq "1 - 100"
      expect(band_capacity_description(band: band_2)).to eq "101 - 200"
    end
  end
end
