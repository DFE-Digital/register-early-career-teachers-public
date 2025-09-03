describe API::DeliveryPartnerSerializer, type: :serializer do
  subject(:response) do
    options = { lead_provider_id: lead_provider.id }
    JSON.parse(described_class.render(delivery_partner, **options))
  end

  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
  let(:delivery_partner) { lead_provider_delivery_partnership.delivery_partner }
  let!(:lead_provider_metadata) { FactoryBot.create(:delivery_partner_lead_provider_metadata, delivery_partner:, lead_provider:) }

  before do
    # Ensure other metadata exists.
    other_lead_provider = FactoryBot.create(:lead_provider)

    FactoryBot.create(:delivery_partner_lead_provider_metadata, delivery_partner:, lead_provider: other_lead_provider)
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
      expect(attributes["cohort"]).to eq(lead_provider_metadata.contract_period_years.map(&:to_s))
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
