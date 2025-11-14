RSpec.describe SchoolPartnerships::FindPreviousReusable do
  subject(:service) { described_class.new }

  let(:school)              { FactoryBot.create(:school) }
  let(:other_school)        { FactoryBot.create(:school) }
  let(:last_lead_provider)  { FactoryBot.create(:lead_provider) }
  let(:other_lead_provider) { FactoryBot.create(:lead_provider) }

  let(:delivery_partner_alpha) { FactoryBot.create(:delivery_partner) }
  let(:delivery_partner_omega) { FactoryBot.create(:delivery_partner) }

  let(:current_year) { 2025 }
  let(:previous_year) { 2024 }
  let(:older_year) { 2023 }
  let(:gap_year)   { 2022 }

  let(:current_contract_period) { FactoryBot.create(:contract_period, year: current_year) }

  let!(:active_lead_provider_for_current_year) do
    FactoryBot.create(:active_lead_provider, :for_year, year: current_year, lead_provider: last_lead_provider)
  end

  def pair_current_year_with(delivery_partner)
    FactoryBot.create(:lead_provider_delivery_partnership,
                      active_lead_provider: active_lead_provider_for_current_year,
                      delivery_partner:)
  end

  describe "#call" do
    context "when a previous-year school partnership exists and the same LP/DP are active together this year" do
      let!(:previous_year_school_partnership) do
        FactoryBot.create(:school_partnership, :for_year,
                          year: previous_year,
                          school:,
                          lead_provider: last_lead_provider,
                          delivery_partner: delivery_partner_alpha)
      end

      before { pair_current_year_with(delivery_partner_alpha) }

      it "returns that previous-year school partnership" do
        result = service.call(school:, last_lead_provider:, current_contract_period:)
        expect(result).to eq(previous_year_school_partnership)
      end
    end

    context "when multiple previous-year school partnerships exist in the same year" do
      let!(:older_previous_school_partnership) do
        FactoryBot.create(:school_partnership, :for_year,
                          year: previous_year,
                          school:,
                          lead_provider: last_lead_provider,
                          delivery_partner: delivery_partner_alpha)
      end

      let!(:latest_previous_school_partnership) do
        FactoryBot.create(:school_partnership, :for_year,
                          year: previous_year,
                          school:,
                          lead_provider: last_lead_provider,
                          delivery_partner: delivery_partner_omega)
      end

      before { pair_current_year_with(delivery_partner_omega) }

      it "returns the previous partnership whose DP is paired this year (the latest valid one)" do
        result = service.call(school:, last_lead_provider:, current_contract_period:)
        expect(result).to eq(latest_previous_school_partnership)
        expect(result.delivery_partner).to eq(delivery_partner_omega)
      end
    end

    context "when the most recent previous year is not paired this year but an older one is" do
      let!(:sp_latest_but_invalid) do
        FactoryBot.create(:school_partnership, :for_year,
                          year: previous_year,
                          school:,
                          lead_provider: last_lead_provider,
                          delivery_partner: delivery_partner_alpha) # not paired this year
      end

      let!(:sp_older_but_valid) do
        FactoryBot.create(:school_partnership, :for_year,
                          year: older_year,
                          school:,
                          lead_provider: last_lead_provider,
                          delivery_partner: delivery_partner_omega) # paired this year
      end

      before { pair_current_year_with(delivery_partner_omega) }

      it "returns the older previous partnership that has a valid current-year pairing" do
        result = service.call(school:, last_lead_provider:, current_contract_period:)
        expect(result).to eq(sp_older_but_valid)
      end
    end

    context "when there are gaps between years (non-consecutive year pairing)" do
      let!(:sp_gap_year) do
        FactoryBot.create(:school_partnership, :for_year,
                          year: gap_year,
                          school:,
                          lead_provider: last_lead_provider,
                          delivery_partner: delivery_partner_omega)
      end

      let!(:sp_prev_but_wrong_dp) do
        FactoryBot.create(:school_partnership, :for_year,
                          year: previous_year,
                          school:,
                          lead_provider: last_lead_provider,
                          delivery_partner: delivery_partner_alpha)
      end

      before { pair_current_year_with(delivery_partner_omega) }

      it "skips invalid recent years and returns the most recent previous year with a valid current pairing" do
        result = service.call(school:, last_lead_provider:, current_contract_period:)
        expect(result).to eq(sp_gap_year)
      end
    end

    context "when the lead provider and delivery partner are not working together this year" do
      let!(:previous_year_school_partnership) do
        FactoryBot.create(:school_partnership, :for_year,
                          year: previous_year,
                          school:,
                          lead_provider: last_lead_provider,
                          delivery_partner: delivery_partner_alpha)
      end

      it "returns nil" do
        result = service.call(school:, last_lead_provider:, current_contract_period:)
        expect(result).to be_nil
      end
    end

    context "when there is also a current-year school partnership for the same pairing" do
      let!(:previous_year_school_partnership) do
        FactoryBot.create(:school_partnership, :for_year,
                          year: previous_year,
                          school:,
                          lead_provider: last_lead_provider,
                          delivery_partner: delivery_partner_alpha)
      end

      let!(:current_year_lead_provider_delivery_partnership) { pair_current_year_with(delivery_partner_alpha) }

      let!(:current_year_school_partnership) do
        FactoryBot.create(:school_partnership,
                          school:,
                          lead_provider_delivery_partnership: current_year_lead_provider_delivery_partnership)
      end

      it "still returns the previous-year partnership (finder is only about 'previous' selection)" do
        result = service.call(school:, last_lead_provider:, current_contract_period:)
        expect(result).to eq(previous_year_school_partnership)
      end
    end

    context "when a current-year partnership exists but for a different DP" do
      let!(:previous_sp) do
        FactoryBot.create(:school_partnership, :for_year,
                          year: previous_year,
                          school:,
                          lead_provider: last_lead_provider,
                          delivery_partner: delivery_partner_alpha)
      end

      before do
        pair_current_year_with(delivery_partner_alpha)
        other_current_pair = FactoryBot.create(:lead_provider_delivery_partnership,
                                               active_lead_provider: active_lead_provider_for_current_year,
                                               delivery_partner: delivery_partner_omega)
        FactoryBot.create(:school_partnership, school:, lead_provider_delivery_partnership: other_current_pair)
      end

      it "returns the previous-year partnership that is valid this year (by DP)" do
        expect(service.call(school:, last_lead_provider:, current_contract_period:)).to eq(previous_sp)
      end
    end

    context "when the lead is not active this year" do
      let!(:sp_prev) do
        FactoryBot.create(:school_partnership, :for_year,
                          year: previous_year,
                          school:,
                          lead_provider: last_lead_provider,
                          delivery_partner: delivery_partner_alpha)
      end

      before { active_lead_provider_for_current_year.destroy! }

      it "returns nil" do
        expect(service.call(school:, last_lead_provider:, current_contract_period:)).to be_nil
      end
    end

    context "cross-school" do
      before do
        FactoryBot.create(:school_partnership, :for_year,
                          year: previous_year,
                          school: other_school,
                          lead_provider: last_lead_provider,
                          delivery_partner: delivery_partner_alpha)
        pair_current_year_with(delivery_partner_alpha)
      end

      it "does not return partnerships from other schools" do
        expect(service.call(school:, last_lead_provider:, current_contract_period:)).to be_nil
      end
    end

    context "guard conditions" do
      it "returns nil when last_lead_provider is nil" do
        expect(service.call(school:, last_lead_provider: nil, current_contract_period:)).to be_nil
      end

      it "returns nil when school is nil" do
        expect(service.call(school: nil, last_lead_provider:, current_contract_period:)).to be_nil
      end

      it "returns nil when current_contract_period is nil" do
        expect(service.call(school:, last_lead_provider:, current_contract_period: nil)).to be_nil
      end

      it "returns nil when there are no previous-year partnerships for the school and last lead provider" do
        result = service.call(school:, last_lead_provider:, current_contract_period:)
        expect(result).to be_nil
      end
    end
  end
end
