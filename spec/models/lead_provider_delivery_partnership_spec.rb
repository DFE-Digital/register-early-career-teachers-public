describe LeadProviderDeliveryPartnership do
  describe "relationships" do
    it { is_expected.to belong_to(:framework_agreement) }
    it { is_expected.to belong_to(:delivery_partner) }
    it { is_expected.to have_many(:school_partnerships) }
    it { is_expected.to have_many(:events).dependent(:nullify) }
    it { is_expected.to have_one(:lead_provider).through(:framework_agreement) }
    it { is_expected.to have_one(:contract_period).through(:framework_agreement) }
  end

  describe "validation" do
    subject { FactoryBot.create(:lead_provider_delivery_partnership) }

    it { is_expected.to validate_presence_of(:framework_agreement_id).with_message("Select a lead provider framework agreement") }
    it { is_expected.to validate_presence_of(:delivery_partner_id).with_message("Select a delivery partner") }
    it { is_expected.to validate_uniqueness_of(:delivery_partner_id).scoped_to(:framework_agreement_id).with_message("Delivery partner and lead provider framework agreement pairing must be unique") }
  end

  describe "scopes" do
    let(:framework_agreement) { FactoryBot.create(:framework_agreement) }
    let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
    let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner:, framework_agreement:) }

    describe ".with_delivery_partner" do
      let(:other_lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership) }

      it "returns the lead provider delivery partnership belonging to the delivery partner" do
        expect(LeadProviderDeliveryPartnership.with_delivery_partner(delivery_partner)).to include(lead_provider_delivery_partnership)
      end

      it "does not return lead provider delivery partnerships belonging to other delivery partners" do
        expect(LeadProviderDeliveryPartnership.with_delivery_partner(delivery_partner)).not_to include(other_lead_provider_delivery_partnership)
      end
    end

    describe ".with_framework_agreement" do
      let(:other_framework_agreement) { FactoryBot.create(:framework_agreement) }

      it "returns the lead provider delivery partnership belonging to the delivery partner" do
        expect(LeadProviderDeliveryPartnership.with_framework_agreement(framework_agreement)).to include(lead_provider_delivery_partnership)
      end

      it "does not return lead provider delivery partnerships belonging to other delivery partners" do
        expect(LeadProviderDeliveryPartnership.with_framework_agreement(framework_agreement)).not_to include(other_framework_agreement)
      end
    end

    describe ".for_contract_period" do
      let(:contract_period_2025) { FactoryBot.create(:contract_period, year: 2025) }
      let(:contract_period_2026) { FactoryBot.create(:contract_period, year: 2026) }
      let(:framework_agreement_2025) { FactoryBot.create(:framework_agreement, contract_period: contract_period_2025) }
      let(:framework_agreement_2026) { FactoryBot.create(:framework_agreement, contract_period: contract_period_2026) }
      let!(:partnership_2025) { FactoryBot.create(:lead_provider_delivery_partnership, framework_agreement: framework_agreement_2025) }
      let!(:partnership_2026) { FactoryBot.create(:lead_provider_delivery_partnership, framework_agreement: framework_agreement_2026) }

      it "returns partnerships for the specified contract period" do
        expect(LeadProviderDeliveryPartnership.for_contract_period(contract_period_2025)).to include(partnership_2025)
      end

      it "does not return partnerships from other contract periods" do
        expect(LeadProviderDeliveryPartnership.for_contract_period(contract_period_2025)).not_to include(partnership_2026)
      end

      it "includes the lead provider relationship" do
        result = LeadProviderDeliveryPartnership.for_contract_period(contract_period_2025).first
        expect(result.association(:framework_agreement)).to be_loaded
        expect(result.framework_agreement.association(:lead_provider)).to be_loaded
      end
    end

    describe ".framework_agreement_ids_for" do
      let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
      let(:other_delivery_partner) { FactoryBot.create(:delivery_partner) }
      let(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }
      let(:other_contract_period) { FactoryBot.create(:contract_period, year: 2026) }

      let(:framework_agreement_with_partnership) { FactoryBot.create(:framework_agreement, contract_period:) }
      let(:framework_agreement_other_delivery_partner) { FactoryBot.create(:framework_agreement, contract_period:) }
      let(:framework_agreement_other_contract_period) { FactoryBot.create(:framework_agreement, contract_period: other_contract_period) }
      let(:framework_agreement_no_partnership) { FactoryBot.create(:framework_agreement, contract_period:) }

      let!(:partnership_same_delivery_partner) do
        FactoryBot.create(:lead_provider_delivery_partnership,
                          delivery_partner:,
                          framework_agreement: framework_agreement_with_partnership)
      end

      let!(:partnership_other_delivery_partner) do
        FactoryBot.create(:lead_provider_delivery_partnership,
                          delivery_partner: other_delivery_partner,
                          framework_agreement: framework_agreement_other_delivery_partner)
      end

      let!(:partnership_other_contract_period) do
        FactoryBot.create(:lead_provider_delivery_partnership,
                          delivery_partner:,
                          framework_agreement: framework_agreement_other_contract_period)
      end

      it "returns framework agreement IDs for the specified delivery partner and contract period" do
        result = LeadProviderDeliveryPartnership.framework_agreement_ids_for(delivery_partner, contract_period)
        expect(result.pluck(:framework_agreement_id)).to contain_exactly(framework_agreement_with_partnership.id)
      end

      it "excludes partnerships with other delivery partners" do
        result = LeadProviderDeliveryPartnership.framework_agreement_ids_for(delivery_partner, contract_period)
        expect(result.pluck(:framework_agreement_id)).not_to include(framework_agreement_other_delivery_partner.id)
      end

      it "excludes partnerships from other contract periods" do
        result = LeadProviderDeliveryPartnership.framework_agreement_ids_for(delivery_partner, contract_period)
        expect(result.pluck(:framework_agreement_id)).not_to include(framework_agreement_other_contract_period.id)
      end

      it "excludes framework agreements with no partnerships" do
        result = LeadProviderDeliveryPartnership.framework_agreement_ids_for(delivery_partner, contract_period)
        expect(result.pluck(:framework_agreement_id)).not_to include(framework_agreement_no_partnership.id)
      end

      it "returns a select query that can be used in subqueries" do
        result = LeadProviderDeliveryPartnership.framework_agreement_ids_for(delivery_partner, contract_period)
        expect(result.to_sql).to include("SELECT")
        expect(result.to_sql).to include("framework_agreement_id")
      end
    end
  end

  describe "declarative updates" do
    let(:instance) { FactoryBot.create(:lead_provider_delivery_partnership, delivery_partner: target) }
    let!(:target) { FactoryBot.create(:delivery_partner) }

    it_behaves_like "a declarative touch model", on_event: %i[create destroy], timestamp_attribute: :api_updated_at
  end
end
