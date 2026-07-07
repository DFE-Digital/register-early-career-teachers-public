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

  describe "#editable?" do
    context "when the band can be edited" do
      it "returns true" do
        expect(helper).to be_editable(band: band_2)
      end
    end

    context "when the band cannot be edited" do
      it "returns false" do
        expect(helper).not_to be_editable(band: band_1)
      end
    end
  end

  describe "#deletable?" do
    context "when the band can be deleted" do
      it "returns true" do
        expect(helper).to be_deletable(band: band_2)
      end
    end

    context "when the band cannot be deleted" do
      it "returns false" do
        expect(helper).not_to be_deletable(band: band_1)
      end
    end
  end

  describe "#bands_can_be_added?" do
    context "when bands can be added to the active lead provider" do
      it "returns true" do
        expect(helper).to be_bands_can_be_added(active_lead_provider:)
      end
    end

    context "when bands cannot be added to the active lead provider" do
      it "returns false" do
        travel_to contract_period.started_on do
          expect(helper).not_to be_bands_can_be_added(active_lead_provider:)
        end
      end
    end
  end

  describe "#bands_can_be_deleted?" do
    context "when bands can be deleted from the active lead provider" do
      it "returns true" do
        expect(helper).to be_bands_can_be_deleted(active_lead_provider:)
      end
    end

    context "when bands cannot be deleted from the active lead provider" do
      it "returns false" do
        travel_to contract_period.started_on do
          expect(helper).not_to be_bands_can_be_deleted(active_lead_provider:)
        end
      end
    end
  end
end
