describe API::DeliveryPartnerSerializer, type: :serializer do
  subject(:response) do
    options = { lead_provider_id: lead_provider.id }
    JSON.parse(described_class.render(delivery_partner, **options))
  end

  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:contract_period) { FactoryBot.create(:contract_period, :current) }
  let(:previous_contract_period) { FactoryBot.create(:contract_period, :previous) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
  let(:delivery_partner) do
    lead_provider_delivery_partnership.delivery_partner.tap do |dp|
      dp.created_at = created_at
      dp.api_updated_at = api_updated_at
    end
  end
  let(:created_at) { Time.utc(2023, 7, 1, 12, 0, 0) }
  let(:api_updated_at) { Time.utc(2023, 7, 2, 12, 0, 0) }

  before do
    # Ensure a delivery partnership exists with a different lead provider
    # and contract period, to ensure it is not included in the `cohort` attribute.
    other_active_lead_provider = FactoryBot.create(:active_lead_provider, contract_period: previous_contract_period)
    FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: other_active_lead_provider, delivery_partner:)
  end

  describe "core attributes" do
    it "serializes correctly" do
      expect(response["id"]).to eq(delivery_partner.api_id)
      expect(response["type"]).to eq("delivery-partner")
    end
  end

  describe "nested attributes" do
    subject(:attributes) { response["attributes"] }

    it "serializes correctly" do
      expect(attributes["name"]).to eq(delivery_partner.name)
      expect(attributes["cohort"]).to contain_exactly(contract_period.year.to_s)
      expect(attributes["created_at"]).to eq(delivery_partner.created_at.utc.rfc3339)
      expect(attributes["updated_at"]).to eq(delivery_partner.api_updated_at.utc.rfc3339)
    end

    context "when there are multiple delivery partnerships for the same lead provider" do
      let(:other_active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: previous_contract_period) }

      before do
        FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: other_active_lead_provider, delivery_partner:)
      end

      it "includes the contract period year only once in the cohort attribute" do
        expect(attributes["cohort"]).to contain_exactly(contract_period.year.to_s, previous_contract_period.year.to_s)
      end
    end
  end
end
