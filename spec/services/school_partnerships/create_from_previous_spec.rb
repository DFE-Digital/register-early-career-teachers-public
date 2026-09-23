RSpec.describe SchoolPartnerships::CreateFromPrevious do
  include ActiveJob::TestHelper

  subject(:service) { described_class.new }

  let(:user)             { FactoryBot.create(:user, :admin) }
  let(:author)           { Sessions::Users::DfEPersona.new(email: user.email) }
  let(:school)           { FactoryBot.create(:school) }
  let(:lead_provider)    { FactoryBot.create(:lead_provider) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }

  let(:previous_year) { 2024 }
  let(:current_year)  { 2025 }

  let!(:previous_contract_period) { FactoryBot.create(:contract_period, year: previous_year) }
  let!(:current_contract_period)  { FactoryBot.create(:contract_period, year: current_year) }

  let!(:framework_agreement_previous_year) do
    FactoryBot.create(:framework_agreement, lead_provider:, contract_period: previous_contract_period)
  end

  let!(:lpdp_previous_year) do
    FactoryBot.create(
      :lead_provider_delivery_partnership,
      framework_agreement: framework_agreement_previous_year,
      delivery_partner:
    )
  end

  let!(:previous_partnership) do
    FactoryBot.create(
      :school_partnership,
      school:,
      lead_provider_delivery_partnership: lpdp_previous_year
    )
  end

  describe "#call" do
    context "when the previous partnership does not exist" do
      it "returns nil and records no reuse event" do
        result = service.call(
          previous_school_partnership_id: 999_999,
          school:,
          author:,
          current_contract_period_year: current_year
        )

        expect(result).to be_nil
        expect(Event.where(event_type: "school_partnership_reused")).to be_empty
      end
    end

    context "when there is no framework agreement for the current year" do
      it "returns nil and records no reuse event" do
        result = service.call(
          previous_school_partnership_id: previous_partnership.id,
          school:,
          author:,
          current_contract_period_year: current_year
        )

        expect(result).to be_nil
        expect(Event.where(event_type: "school_partnership_reused")).to be_empty
      end
    end

    context "when there is a framework agreement for the current year but no matching LP/DP pairing" do
      let!(:framework_agreement_current_year) do
        FactoryBot.create(:framework_agreement, lead_provider:, contract_period: current_contract_period)
      end

      it "returns nil and records no reuse event" do
        result = service.call(
          previous_school_partnership_id: previous_partnership.id,
          school:,
          author:,
          current_contract_period_year: current_year
        )

        expect(result).to be_nil
        expect(Event.where(event_type: "school_partnership_reused")).to be_empty
      end
    end

    context "when a matching LP/DP pairing exists in the current year" do
      let!(:framework_agreement_current_year) do
        FactoryBot.create(:framework_agreement, lead_provider:, contract_period: current_contract_period)
      end

      let!(:lpdp_current_year) do
        FactoryBot.create(
          :lead_provider_delivery_partnership,
          framework_agreement: framework_agreement_current_year,
          delivery_partner:
        )
      end

      it "creates a partnership with the current-year LP/DP pairing and records a reuse event" do
        result = nil

        expect {
          result = service.call(
            previous_school_partnership_id: previous_partnership.id,
            school:,
            author:,
            current_contract_period_year: current_year
          )
        }.to change(SchoolPartnership, :count).by(1)

        expect(result).to be_persisted
        expect(result.school).to eq(school)
        expect(result.lead_provider_delivery_partnership).to eq(lpdp_current_year)

        event = Event.where(event_type: "school_partnership_reused").sole
        expect(event).to have_attributes(
          school_partnership_id: result.id,
          school_id: school.id,
          lead_provider_id: lead_provider.id
        )
        expect(event.metadata).to include(
          "previous_school_partnership_id" => previous_partnership.id,
          "reused_into_contract_period_year" => current_year
        )
      end
    end
  end
end
