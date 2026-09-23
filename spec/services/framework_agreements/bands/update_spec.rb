RSpec.describe FrameworkAgreements::Bands::Update do
  subject(:service) { described_class.new(author:, band:, capacity:) }

  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:framework_agreement) { FactoryBot.create(:framework_agreement, contract_period:) }
  let(:band) { FactoryBot.create(:framework_agreement_band, framework_agreement:, capacity: 500) }

  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }

  describe "#update!" do
    context "with valid capacity" do
      let(:capacity) { 750 }

      it "updates the record" do
        expect { service.update! }.to change { band.reload.capacity }.to(capacity)
      end

      it "records an `framework_agreement_band_updated` event" do
        service.update!

        event = Event.where(event_type: "band_updated").sole
        expect(event).to have_attributes(
          framework_agreement_id: band.framework_agreement_id,
          lead_provider_id: band.framework_agreement.lead_provider_id
        )
        expect(event.metadata).to eq("capacity" => [500, 750])
      end
    end
  end

  context "with invalid params" do
    let(:capacity) { "banana" }

    it "raises an error" do
      expect { service.update! }.to raise_error(ActiveRecord::RecordInvalid).with_message(/Capacity must be a number greater than zero/)
      expect(Event.where(event_type: "band_updated")).to be_empty
    end
  end
end
