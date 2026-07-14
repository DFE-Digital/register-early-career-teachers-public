RSpec.describe ActiveLeadProviders::Bands::Update do
  subject(:service) { described_class.new(author:, band:, capacity:) }

  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period:) }
  let(:band) { FactoryBot.create(:active_lead_provider_band, active_lead_provider:, capacity: 500) }

  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }

  describe "#update!" do
    context "with valid capacity" do
      let(:capacity) { 750 }

      before do
        allow(Events::Record).to receive(:record_active_lead_provider_band_updated_event!)
      end

      it "updates the record" do
        expect { service.update! }.to change { band.reload.capacity }.to(capacity)
      end

      it "records an `active_lead_provider_band_updated` event" do
        service.update!
        modifications = { "capacity" => [500, 750] }

        expect(Events::Record).to have_received(:record_active_lead_provider_band_updated_event!).with(author:, band:, modifications:)
      end
    end
  end

  context "with invalid params" do
    let(:capacity) { "banana" }

    before do
      allow(Events::Record).to receive(:record_active_lead_provider_band_updated_event!)
    end

    it "raises an error" do
      expect { service.update! }.to raise_error(ActiveRecord::RecordInvalid).with_message(/Capacity must be a number greater than zero/)
      expect(Events::Record).not_to have_received(:record_active_lead_provider_band_updated_event!)
    end
  end
end
