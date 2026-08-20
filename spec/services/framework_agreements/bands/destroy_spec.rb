describe FrameworkAgreements::Bands::Destroy do
  subject(:service) { described_class.new(author:, band:) }

  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:) }
  let!(:band) { FactoryBot.create(:framework_agreement_band, framework_agreement:, capacity: 500) }

  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }

  describe "#destroy!" do
    before do
      allow(Events::Record).to receive(:record_framework_agreement_band_deleted_event!)
    end

    it "destroys the band" do
      expect { service.destroy! }.to change(FrameworkAgreement::Band, :count).by(-1)
    end

    it "records a schedule_deleted event" do
      service.destroy!

      expect(Events::Record).to have_received(:record_framework_agreement_band_deleted_event!).with(
        author:,
        framework_agreement:,
        band_letter: band.letter
      )
    end

    context "when the band is not the last in the allocation order" do
      before do
        FactoryBot.create(:framework_agreement_band, framework_agreement:)
      end

      it "raises an error and does not delete the band" do
        expect { service.destroy! }
          .to raise_error(FrameworkAgreements::Bands::Destroy::DeletionError)
          .and(not_change(FrameworkAgreement::Band, :count))
      end
    end

    context "when the contract_period has started" do
      it "raises an error and does not delete the band" do
        travel_to contract_period.started_on do
          expect { service.destroy! }
            .to raise_error(FrameworkAgreements::Bands::Destroy::DeletionError)
            .and(not_change(FrameworkAgreement::Band, :count))
        end
      end
    end
  end
end
