describe API::DeliveryPartnerSerializer, type: :serializer do
  subject(:response) do
    options = { lead_provider_id: lead_provider.id }
    JSON.parse(described_class.render(delivery_partner, **options))
  end

  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
  let(:delivery_partner) { lead_provider_delivery_partnership.delivery_partner }

  before do
    # Ensure other metadata exists for another lead provider.
    FactoryBot.create(:lead_provider)
    Metadata::Manager.refresh_all_metadata!
  end

  describe "core attributes" do
    it "serializes `id`" do
      expect(response["id"]).to eq(delivery_partner.api_id)
    end

    it "serializes `type`" do
      expect(response["type"]).to eq("delivery-partner")
    end
  end

  describe "nested attributes" do
    subject(:attributes) { response["attributes"] }

    it "serializes `name`" do
      expect(attributes["name"]).to eq(delivery_partner.name)
    end

    it "serializes `cohort`" do
      expect(attributes["cohort"]).to contain_exactly(active_lead_provider.contract_period_year.to_s)
    end

    it "serializes `created_at`" do
      expect(attributes["created_at"]).to eq(delivery_partner.created_at.utc.rfc3339)
    end

    it "serializes `updated_at`" do
      delivery_partner.update!(api_updated_at: 3.days.ago)
      expect(attributes["updated_at"]).to eq(delivery_partner.api_updated_at.utc.rfc3339)
    end
  end
end
