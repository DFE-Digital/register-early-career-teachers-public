describe ActiveLeadProviders::Create do
  subject(:service) { described_class.new(author:, contract_period:, lead_provider_id:) }

  let(:contract_period) { FactoryBot.create(:contract_period, :next) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:user) { FactoryBot.create(:user, :admin) }
  let(:author) { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:seed) { instance_double(ActiveLeadProviders::SeedFromPrevious, call: true) }

  before do
    allow(ActiveLeadProviders::SeedFromPrevious).to receive(:new).and_return(seed)
    allow(Events::Record).to receive(:record_active_lead_provider_created_event!)
  end

  context "with a valid lead provider" do
    let(:lead_provider_id) { lead_provider.id }

    it "builds and saves the active lead provider, records the created event, then seeds it from the previous period" do
      result = nil
      expect { result = service.call }.to change(ActiveLeadProvider, :count).by(1)

      expect(result).to be_persisted
      expect(result).to have_attributes(contract_period_year: contract_period.year, lead_provider_id: lead_provider.id)
      expect(Events::Record).to have_received(:record_active_lead_provider_created_event!).with(author:, active_lead_provider: result)
      expect(ActiveLeadProviders::SeedFromPrevious).to have_received(:new).with(active_lead_provider: result)
      expect(seed).to have_received(:call)
    end
  end

  context "with an invalid lead provider" do
    let(:lead_provider_id) { nil }

    it "does not save, record an event, or seed, and returns the unpersisted record carrying its errors" do
      result = nil
      expect { result = service.call }.not_to change(ActiveLeadProvider, :count)

      expect(result).not_to be_persisted
      expect(result.errors[:lead_provider_id]).to include("Choose a lead provider")
      expect(Events::Record).not_to have_received(:record_active_lead_provider_created_event!)
      expect(ActiveLeadProviders::SeedFromPrevious).not_to have_received(:new)
    end
  end
end
