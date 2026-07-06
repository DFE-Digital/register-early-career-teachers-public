describe Admin::Finance::Bands do
  subject(:band_service) { described_class.new(active_lead_provider:) }

  let(:started_on) { 1.month.from_now }
  let(:contract_period) { FactoryBot.create(:contract_period, started_on:) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }

  let!(:band_1) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:) }
  let!(:band_2) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:) }

  describe "#label_for" do
    it "returns a label for the band using its letter" do
      expect(band_service.label_for(band: band_1)).to eq "Band A"
      expect(band_service.label_for(band: band_2)).to eq "Band B"
    end
  end

  describe "#capacity_description_for" do
    it "returns a string with the capacity range for the band" do
      expect(band_service.capacity_description_for(band: band_1)).to eq "1 - 100"
      expect(band_service.capacity_description_for(band: band_2)).to eq "101 - 200"
    end
  end

  describe "#bands_can_be_added?" do
    subject { band_service.bands_can_be_added? }

    context "when the contract period has not yet started" do
      context "when there are no contracts for the provider" do
        it { is_expected.to be_truthy }
      end

      context "when there are contracts for the provider" do
        before do
          FactoryBot.create(:contract, active_lead_provider:)
        end

        it { is_expected.to be_falsey }
      end
    end

    context "when the contract period has started" do
      let(:started_on) { 1.month.ago }

      context "when there are no contracts for the provider" do
        it { is_expected.to be_falsey }
      end

      context "when there are contracts for the provider" do
        before do
          FactoryBot.create(:contract, active_lead_provider:)
        end

        it { is_expected.to be_falsey }
      end
    end
  end

  describe "#editable?" do
    context "when the band is the last in the allocation order" do
      it "is expected to be true" do
        expect(band_service.editable?(band: band_2)).to be_truthy
      end
    end

    context "when the band is not the last in the allocation order" do
      it "is expected to be false" do
        expect(band_service.editable?(band: band_1)).to be_falsey
      end
    end
  end

  describe "#deletable_band?" do
    context "when the contract period has not yet started" do
      context "when there are no contracts for the provider" do
        context "when the band is the last in the allocation order" do
          it "is expected to be true" do
            expect(band_service.deletable_band?(band: band_2)).to be_truthy
          end
        end
        context "when the band is not the last in the allocation order" do
          it "is expected to be false" do
            expect(band_service.deletable_band?(band: band_1)).to be_falsey
          end
        end
      end

      context "when there are contracts for the provider" do
        before do
          FactoryBot.create(:contract, active_lead_provider:)
        end

        context "when the band is the last in the allocation order" do
          it "is expected to be false" do
            expect(band_service.deletable_band?(band: band_2)).to be_falsey
          end
        end
        context "when the band is not the last in the allocation order" do
          it "is expected to be false" do
            expect(band_service.deletable_band?(band: band_1)).to be_falsey
          end
        end
      end
    end

    context "when the contract period has started" do
      let(:started_on) { 1.month.ago }

      context "when there are no contracts for the provider" do
        context "when the band is the last in the allocation order" do
          it "is expected to be false" do
            expect(band_service.deletable_band?(band: band_2)).to be_falsey
          end
        end
        context "when the band is not the last in the allocation order" do
          it "is expected to be false" do
            expect(band_service.deletable_band?(band: band_1)).to be_falsey
          end
        end
      end

      context "when there are contracts for the provider" do
        before do
          FactoryBot.create(:contract, active_lead_provider:)
        end

        context "when the band is the last in the allocation order" do
          it "is expected to be false" do
            expect(band_service.deletable_band?(band: band_2)).to be_falsey
          end
        end
        context "when the band is not the last in the allocation order" do
          it "is expected to be false" do
            expect(band_service.deletable_band?(band: band_1)).to be_falsey
          end
        end
      end
    end
  end

  describe "#last?" do
    context "when the band is the last in the allocation order" do
      it "is expected to be true" do
        expect(band_service.deletable_band?(band: band_2)).to be_truthy
      end
    end

    context "when the band is not the last in the allocation order" do
      it "is expected to be false" do
        expect(band_service.deletable_band?(band: band_1)).to be_falsey
      end
    end
  end

  describe "delete!" do
    context "when the band is '#deletable?'" do
      it "deletes the band" do
        expect {
          band_service.delete!(band: band_2)
        }.to change(ActiveLeadProvider::Band, :count).by(-1)
      end
    end

    context "when the band is not the last band in the allocation order" do
      it "raises an error" do
        expect {
          band_service.delete!(band: band_1)
        }.to raise_error.with_message("Band cannot be deleted")
      end
    end

    context "when the contract period has started" do
      let(:started_on) { 1.month.ago }

      it "raises an error" do
        expect {
          band_service.delete!(band: band_2)
        }.to raise_error.with_message("Band cannot be deleted")
      end
    end

    context "when there is a contract" do
      before do
        FactoryBot.create(:contract, active_lead_provider:)
      end

      it "raises an error" do
        expect {
          band_service.delete!(band: band_2)
        }.to raise_error.with_message("Band cannot be deleted")
      end
    end
  end
end
