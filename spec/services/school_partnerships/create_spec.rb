RSpec.describe SchoolPartnerships::Create do
  let(:contract_period) { FactoryBot.create(:contract_period) }

  let(:school) { FactoryBot.create(:school, :eligible) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }

  let!(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
  let!(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:) }

  let(:service) do
    described_class.new(
      school:,
      lead_provider_delivery_partnership:
    )
  end

  describe "#create" do
    subject(:create_school_partnership) { service.create }

    it "creates a school partnership" do
      created_school_partnership = nil

      expect { created_school_partnership = create_school_partnership }.to change(SchoolPartnership, :count).by(1)

      expect(created_school_partnership).to have_attributes(school:, lead_provider_delivery_partnership:)
    end

    it "records a school partnership created event" do
      allow(Events::Record).to receive(:record_school_partnership_created_event!).once.and_call_original

      school_partnership = create_school_partnership

      expect(Events::Record).to have_received(:record_school_partnership_created_event!).once.with(
        hash_including(
          {
            school_partnership:,
            author: kind_of(Events::LeadProviderAPIAuthor),
          }
        )
      )
    end
  end
end
