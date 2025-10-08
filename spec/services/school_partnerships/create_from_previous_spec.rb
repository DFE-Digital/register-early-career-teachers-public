RSpec.describe SchoolPartnerships::CreateFromPrevious do
  subject(:service) { described_class.new }

  let(:author)           { FactoryBot.create(:user) }
  let(:school)           { FactoryBot.create(:school) }
  let(:lead_provider)    { FactoryBot.create(:lead_provider) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }

  let(:previous_year) { 2024 }
  let(:current_year)  { 2025 }

  let!(:cp_previous) { FactoryBot.create(:contract_period, year: previous_year) }
  let!(:cp_current) { FactoryBot.create(:contract_period, year: current_year) }

  let!(:active_lp_prev_year) do
    FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: cp_previous)
  end

  let!(:lpdp_prev_year) do
    FactoryBot.create(:lead_provider_delivery_partnership,
                      active_lead_provider: active_lp_prev_year,
                      delivery_partner:)
  end

  let!(:previous_partnership) do
    FactoryBot.create(:school_partnership,
                      school:,
                      lead_provider_delivery_partnership: lpdp_prev_year)
  end

  describe "#call" do
    before do
      allow(Events::Record)
        .to receive(:record_school_partnership_created_event!)
        .and_return(true)
    end

    context "when the previous partnership does not exist" do
      it "returns nil" do
        result = service.call(
          previous_school_partnership_id: 999_999,
          school:,
          author:,
          current_contract_period_year: current_year
        )
        expect(result).to be_nil
      end
    end

    context "when there is no active lead provider for the current year" do
      it "returns nil" do
        result = service.call(
          previous_school_partnership_id: previous_partnership.id,
          school:,
          author:,
          current_contract_period_year: current_year
        )
        expect(result).to be_nil
      end
    end

    context "when there is an active lead provider for the current year but no matching LP/DP pairing" do
      let!(:active_lp_current_year) do
        FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: cp_current)
      end

      it "returns nil" do
        result = service.call(
          previous_school_partnership_id: previous_partnership.id,
          school:,
          author:,
          current_contract_period_year: current_year
        )
        expect(result).to be_nil
      end
    end

    context "when a matching LP/DP pairing exists in the current year" do
      let!(:active_lp_current_year) do
        FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: cp_current)
      end

      let!(:lpdp_current_year) do
        FactoryBot.create(:lead_provider_delivery_partnership,
                          active_lead_provider: active_lp_current_year,
                          delivery_partner:) # must match previous DP
      end

      it "creates a partnership with the current-year LP/DP pairing" do
        result = nil

        expect {
          result = service.call(
            previous_school_partnership_id: previous_partnership.id,
            school:,
            author:,
            current_contract_period_year: current_year
          )
        }.to change(SchoolPartnership, :count).by(1)

        aggregate_failures do
          expect(result).to be_persisted
          expect(result.school).to eq(school)
          expect(result.lead_provider_delivery_partnership).to eq(lpdp_current_year)
        end
      end
    end
  end
end
