RSpec.describe SchoolPartnerships::CreateFromPrevious do
  include ActiveJob::TestHelper

  subject(:service) { described_class.new }

  let(:author)           { FactoryBot.create(:user) }
  let(:school)           { FactoryBot.create(:school) }
  let(:lead_provider)    { FactoryBot.create(:lead_provider) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }

  let(:previous_year) { 2024 }
  let(:current_year)  { 2025 }

  let!(:previous_contract_period) { FactoryBot.create(:contract_period, year: previous_year) }
  let!(:current_contract_period)  { FactoryBot.create(:contract_period, year: current_year) }

  let!(:active_lp_previous_year) do
    FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: previous_contract_period)
  end

  let!(:lpdp_previous_year) do
    FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider: active_lp_previous_year,
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
    before do
      allow(Events::Record).to receive_messages(
        record_school_partnership_created_event!: true,
        record_school_partnership_reused_event!: true
      )
    end

    context "when the previous partnership does not exist" do
      it "returns nil and records no reuse event" do
        result = service.call(
          previous_school_partnership_id: 999_999,
          school:,
          author:,
          current_contract_period_year: current_year
        )

        expect(result).to be_nil
        expect(Events::Record).not_to have_received(:record_school_partnership_reused_event!)
      end
    end

    context "when there is no active lead provider for the current year" do
      it "returns nil and records no reuse event" do
        result = service.call(
          previous_school_partnership_id: previous_partnership.id,
          school:,
          author:,
          current_contract_period_year: current_year
        )

        expect(result).to be_nil
        expect(Events::Record).not_to have_received(:record_school_partnership_reused_event!)
      end
    end

    context "when there is an active lead provider for the current year but no matching LP/DP pairing" do
      let!(:active_lp_current_year) do
        FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: current_contract_period)
      end

      it "returns nil and records no reuse event" do
        result = service.call(
          previous_school_partnership_id: previous_partnership.id,
          school:,
          author:,
          current_contract_period_year: current_year
        )

        expect(result).to be_nil
        expect(Events::Record).not_to have_received(:record_school_partnership_reused_event!)
      end
    end

    context "when a matching LP/DP pairing exists in the current year" do
      let!(:active_lp_current_year) do
        FactoryBot.create(:active_lead_provider, lead_provider:, contract_period: current_contract_period)
      end

      let!(:lpdp_current_year) do
        FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: active_lp_current_year,
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

        expect(Events::Record)
          .to have_received(:record_school_partnership_reused_event!)
          .with(hash_including(
                  school_partnership: result,
                  previous_school_partnership_id: previous_partnership.id,
                  happened_at: kind_of(ActiveSupport::TimeWithZone)
                ))
      end
    end
  end
end
