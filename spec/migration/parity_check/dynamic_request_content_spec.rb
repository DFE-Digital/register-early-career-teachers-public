RSpec.describe ParityCheck::DynamicRequestContent do
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
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

    context "when fetching school_id" do
      let(:identifier) { :school_id }
      let!(:school_partnership) { FactoryBot.create(:school_partnership, school:) }
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

    context "when fetching delivery_partner_id" do
      let(:identifier) { :delivery_partner_id }
      let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
      let!(:delivery_partner) { lead_provider_delivery_partnership.delivery_partner }

      before do
        # Delivery partner for different lead provider should not be used.
        FactoryBot.create(:delivery_partner)
      end

      it { is_expected.to eq(delivery_partner.api_id) }
    end

    context "when fetching example_body" do
      let(:identifier) { :example_body }

      it "returns the example body" do
        expect(fetch).to eq({
          data: {
            type: "statements",
            attributes: {
              content: "This is an example request body.",
            },
          },
        })
      end
    end

    context "when fetching `partnership_id`" do
      let(:identifier) { :partnership_id }
      let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, lead_provider:) }
      let(:lead_provider_delivery_partnership) { FactoryBot.create(:lead_provider_delivery_partnership, active_lead_provider:) }
      let!(:partnership) { FactoryBot.create(:school_partnership, lead_provider_delivery_partnership:) }

      before do
        # Partnership for different lead provider should not be used.
        FactoryBot.create(:school_partnership)
      end

      it { is_expected.to eq(partnership.api_id) }
    end
  end
end
