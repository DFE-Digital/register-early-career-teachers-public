RSpec.describe ParityCheck::DynamicRequestContent do
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
  let(:instance) { described_class.new(lead_provider:) }

  describe "#fetch" do
    subject(:fetch) { instance.fetch(identifier) }

    context "when fetching an unrecognized identifier" do
      let(:identifier) { :unrecognized_identifier }

      it { expect { fetch }.to raise_error(described_class::UnrecognizedIdentifierError, "Identifier not recognized: unrecognized_identifier") }
    end

    context "when fetching statement_id" do
      let(:identifier) { :statement_id }
      let!(:statement) { FactoryBot.create(:statement, :output_fee, lead_provider:) }

      before do
        # Statement for different lead provider should not be used.
        FactoryBot.create(:statement)
        # Statement for service fee should not be used
        FactoryBot.create(:statement, :service_fee, lead_provider:)
      end

      it { is_expected.to eq(statement.api_id) }
    end

    context "when fetching school_id", :with_metadata do
      let(:identifier) { :school_id }
      let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
      let!(:school_partnership) { FactoryBot.create(:school_partnership, school:, active_lead_provider:) }
      let!(:school) { FactoryBot.create(:school, :eligible, :not_cip_only) }

      before do
        # Ineligible school
        FactoryBot.create(:school, :ineligible, :not_cip_only)
          .tap { it.gias_school.update!(funding_eligibility: :ineligible) }
        # CIP only school
        FactoryBot.create(:school, :eligible, :cip_only)
      end

      it { is_expected.to eq(school.api_id) }
    end

    context "when fetching delivery_partner_id", :with_metadata do
      let(:identifier) { :delivery_partner_id }
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
      let!(:delivery_partner) { lead_provider_delivery_partnership.delivery_partner }

      before do
        # Delivery partner for different lead provider should not be used.
        FactoryBot.create(:delivery_partner)
      end

      it { is_expected.to eq(delivery_partner.api_id) }
    end

    context "when fetching `partnership_id`" do
      let(:identifier) { :partnership_id }
      let(:ecf_lead_provider) { FactoryBot.create(:migration_lead_provider, id: lead_provider.ecf_id) }
      let!(:ecf_partnership) { FactoryBot.create(:migration_partnership, lead_provider: ecf_lead_provider) }

      before do
        # Partnership for different lead provider should not be used.
        FactoryBot.create(:migration_partnership)
        # Challenged.
        FactoryBot.create(:migration_partnership, lead_provider: ecf_lead_provider, challenged_at: Time.current)
        # Relationship.
        FactoryBot.create(:migration_partnership, lead_provider: ecf_lead_provider, relationship: true)
      end

      it { is_expected.to eq(ecf_partnership.id) }
    end

    context "when fetching partnership_create_body" do
      let(:identifier) { :partnership_create_body }
      let!(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
      let!(:school) { FactoryBot.create(:school, :eligible, :not_cip_only) }

      before do
        # Disabled contract period
        disabled_contract_period = FactoryBot.create(:contract_period, enabled: false)
        other_active_lead_provider = FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: disabled_contract_period)
        FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider: other_active_lead_provider)
        # Different lead provider
        FactoryBot.create(:lead_provider_delivery_partnership)
        # Ineligible school
        FactoryBot.create(:school, :ineligible)
        # CIP only school
        FactoryBot.create(:school, :eligible, :cip_only)
      end

      it "returns a partnership create body" do
        expect(fetch).to eq({
          data: {
            type: "partnerships",
            attributes: {
              cohort: active_lead_provider.contract_period_year,
              school_id: school.api_id,
              delivery_partner_id: lead_provider_delivery_partnership.delivery_partner.api_id,
            },
          },
        })
      end

      context "when a contract period does not exist" do
        let(:active_lead_provider) {}
        let(:lead_provider_delivery_partnership) {}

        it { expect(fetch).to be_nil }
      end

      context "when a lead provider delivery partnership does not exist" do
        let(:lead_provider_delivery_partnership) {}

        it { expect(fetch).to be_nil }
      end

      context "when a school does not exist" do
        let(:school) {}

        it { expect(fetch).to be_nil }
      end
    end

    context "when fetching partnership_update_body" do
      let(:identifier) { :partnership_update_body }
      let(:cohort) { FactoryBot.create(:migration_cohort, start_year: active_lead_provider.contract_period_year) }
      let(:ecf_lead_provider) { FactoryBot.create(:migration_lead_provider, id: lead_provider.ecf_id) }
      let!(:ecf_partnership) { FactoryBot.create(:migration_partnership, cohort:, lead_provider: ecf_lead_provider) }
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
      let!(:school_partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:, api_id: ecf_partnership.id) }
      let!(:other_delivery_partner) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:).delivery_partner }

      before do
        # Different lead provider.
        FactoryBot.create(:migration_partnership, cohort:)
        # Challenged.
        FactoryBot.create(:migration_partnership, lead_provider: ecf_lead_provider, challenged_at: Time.current)
        # Relationship.
        FactoryBot.create(:migration_partnership, lead_provider: ecf_lead_provider, relationship: true)
      end

      it "returns a partnership update body" do
        expect(fetch).to eq({
          data: {
            type: "partnerships",
            attributes: {
              delivery_partner_id: other_delivery_partner.api_id,
            },
          },
        })
      end

      context "when a school partnership does not exist" do
        let(:school_partnership) {}

        it { expect(fetch).to be_nil }
      end

      context "when another delivery partner does not exist" do
        let(:other_delivery_partner) {}

        it { expect(fetch).to be_nil }
      end
    end

    context "when fetching the same identifier more than once" do
      let(:identifier) { :statement_id }
      let!(:statement) { FactoryBot.create(:statement, :output_fee, lead_provider:) }

      it "memoises the returned value for the same identifier in subsequent calls" do
        expect(API::Statements::Query).to receive(:new).once.and_call_original

        2.times { instance.fetch(identifier) }
      end
    end
  end
end
