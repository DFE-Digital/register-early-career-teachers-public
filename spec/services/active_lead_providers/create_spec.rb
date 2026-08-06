describe ActiveLeadProviders::Create do
  subject(:call_service) { described_class.(author:, contract_period:, lead_provider_id:) }

  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }

  before do
    allow(ActiveLeadProviders::SeedFromPrevious).to receive(:call)
    allow(Events::Record).to receive(:record_active_lead_provider_created_event!)
  end

  context "with a valid lead provider" do
    let(:lead_provider_id) { lead_provider.id }

    it "builds and saves the active lead provider, records the created event, then seeds it from the previous period" do
      result = nil
      expect { result = call_service }.to change(ActiveLeadProvider, :count).by(1)

      expect(result).to be_persisted
      expect(result).to have_attributes(contract_period_year: contract_period.year, lead_provider_id: lead_provider.id)
      expect(Events::Record).to have_received(:record_active_lead_provider_created_event!).with(author:, active_lead_provider: result)
      expect(ActiveLeadProviders::SeedFromPrevious).to have_received(:call).with(active_lead_provider: result)
    end
  end

  context "with an invalid lead provider" do
    let(:lead_provider_id) { nil }

    it "does not save, record an event, or seed, and returns the unpersisted record carrying its errors" do
      result = nil
      expect { result = call_service }.not_to change(ActiveLeadProvider, :count)

      expect(result).not_to be_persisted
      expect(result.errors[:lead_provider_id]).to include("Choose a lead provider")
      expect(Events::Record).not_to have_received(:record_active_lead_provider_created_event!)
      expect(ActiveLeadProviders::SeedFromPrevious).not_to have_received(:call)
    end
  end
end
