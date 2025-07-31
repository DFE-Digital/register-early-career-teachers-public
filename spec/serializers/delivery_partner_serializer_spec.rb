describe DeliveryPartnerSerializer, type: :serializer do
  subject(:response) do
    JSON.parse(described_class.render(delivery_partner, lead_provider:))
  end

  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:contract_period) { FactoryBot.create(:contract_period, year: 2024) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:, contract_period:) }
  let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
  let(:delivery_partner) { lead_provider_delivery_partnership.delivery_partner }

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
      expect(attributes["cohort"]).to contain_exactly("2024")
    end

    it "serializes `created_at`" do
      expect(attributes["created_at"]).to eq(delivery_partner.created_at.utc.rfc3339)
    end

    it "serializes `updated_at`" do
      delivery_partner.update!(api_updated_at: 3.days.ago)
      expect(attributes["updated_at"]).to eq(delivery_partner.api_updated_at.utc.rfc3339)
    end

    context "when `transient_cohorts` is present" do
      before do
        # We simulate the transient cohorts here; it is usually set in the query service.
        class << delivery_partner
          attr_accessor :transient_cohorts
        end

        delivery_partner.transient_cohorts = %w[2024 2025]
      end

      it "includes the transient cohorts" do
        expect(attributes["cohort"]).to contain_exactly("2024", "2025")
      end
    end

    context "when there are delivery partnerships for other lead providers" do
      before do
        other_lead_provider = FactoryBot.create(:lead_provider)
        other_contract_period = FactoryBot.create(:contract_period, year: 2023)
        active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider: other_lead_provider, contract_period: other_contract_period)
        FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:)
      end

      it "does not include other lead provider's cohorts" do
        expect(attributes["cohort"]).to contain_exactly("2024")
      end
    end

    context "when there are multiple delivery partnerships with different contract periods for the same lead provider" do
      before do
        # Delivery partnership with a different contract period.
        other_contract_period = FactoryBot.create(:contract_period, year: 2023)
        active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: other_contract_period)
        FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:, delivery_partner:)
      end

      it "serializes `cohort` with unique contract periods" do
        expect(attributes["cohort"]).to contain_exactly("2023", "2024")
      end
    end
  end
end
