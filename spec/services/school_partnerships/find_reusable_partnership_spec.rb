RSpec.describe SchoolPartnerships::FindReusablePartnership do
  subject(:service) { described_class.new }

  let(:school) { FactoryBot.create(:school) }
  let(:other_school) { FactoryBot.create(:school) }

  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:other_lead_provider) { FactoryBot.create(:lead_provider) }

  let(:delivery_partner_alpha) { FactoryBot.create(:delivery_partner) }
  let(:delivery_partner_omega) { FactoryBot.create(:delivery_partner) }

  let(:current_year) { 2025 }
  let(:previous_year) { 2024 }
  let(:older_year) { 2023 }
  let(:gap_year) { 2022 }

  let(:current_contract_period) { FactoryBot.create(:contract_period, year: current_year) }

  def find_or_create_contract_period!(year:)
    ContractPeriod.find_by(year:) || FactoryBot.create(:contract_period, year:)
  end

  def find_or_create_active_lead_provider!(lead_provider:, year:)
    contract_period = find_or_create_contract_period!(year:)

    ActiveLeadProvider.find_or_create_by!(lead_provider:, contract_period:)
  end

  def create_lead_provider_delivery_partnership!(lead_provider:, delivery_partner:, year:)
    active_lead_provider = find_or_create_active_lead_provider!(lead_provider:, year:)

    FactoryBot.create(
      :lead_provider_delivery_partnership,
      active_lead_provider:,
      delivery_partner:
    )
  end

  def create_school_partnership!(school:, lead_provider:, delivery_partner:, year:)
    lead_provider_delivery_partnership =
      create_lead_provider_delivery_partnership!(
        lead_provider:,
        delivery_partner:,
        year:
      )

    FactoryBot.create(
      :school_partnership,
      school:,
      lead_provider_delivery_partnership:
    )
  end

  def call_service(school: self.school, lead_provider: self.lead_provider, contract_period: current_contract_period)
    service.call(school:, lead_provider:, contract_period:)
  end

  describe "#call" do
    context "guard conditions" do
      it "returns nil when school is nil" do
        expect(service.call(school: nil, lead_provider:, contract_period: current_contract_period)).to be_nil
      end

      it "returns nil when lead_provider is nil" do
        expect(service.call(school:, lead_provider: nil, contract_period: current_contract_period)).to be_nil
      end

      it "returns nil when contract_period is nil" do
        expect(service.call(school:, lead_provider:, contract_period: nil)).to be_nil
      end
    end

    context "when a current-year school partnership exists (scenario 1)" do
      let!(:current_year_school_partnership) do
        create_school_partnership!(
          school:,
          lead_provider:,
          delivery_partner: delivery_partner_alpha,
          year: current_year
        )
      end

      it "returns the current-year school partnership" do
        expect(call_service).to eq(current_year_school_partnership)
      end

      it "does not return partnerships from other schools" do
        create_school_partnership!(
          school: other_school,
          lead_provider:,
          delivery_partner: delivery_partner_alpha,
          year: current_year
        )

        expect(call_service).to eq(current_year_school_partnership)
      end

      it "does not return partnerships for other lead providers" do
        create_school_partnership!(
          school:,
          lead_provider: other_lead_provider,
          delivery_partner: delivery_partner_alpha,
          year: current_year
        )

        expect(call_service).to eq(current_year_school_partnership)
      end
    end

    context "when there is no current-year partnership but a previous-year partnership is compatible (scenario 2)" do
      before do
        create_lead_provider_delivery_partnership!(
          lead_provider:,
          delivery_partner: delivery_partner_alpha,
          year: current_year
        )
      end

      it "returns the most recent compatible previous-year partnership" do
        previous_year_school_partnership =
          create_school_partnership!(
            school:,
            lead_provider:,
            delivery_partner: delivery_partner_alpha,
            year: previous_year
          )

        expect(call_service).to eq(previous_year_school_partnership)
      end

      context "when multiple previous-year partnerships exist in the same year" do
        let!(:alpha_prev) do
          create_school_partnership!(
            school:,
            lead_provider:,
            delivery_partner: delivery_partner_alpha,
            year: previous_year
          )
        end

        let!(:omega_prev) do
          create_school_partnership!(
            school:,
            lead_provider:,
            delivery_partner: delivery_partner_omega,
            year: previous_year
          )
        end

        it "returns the previous-year partnership whose delivery partner is paired this year" do
          result = call_service
          expect(result).to eq(alpha_prev)
          expect(result).not_to eq(omega_prev)
        end
      end

      context "when the most recent previous year is not paired this year but an older one is" do
        let!(:previous_year_incompatible_partnership) do
          create_school_partnership!(
            school:,
            lead_provider:,
            delivery_partner: delivery_partner_omega, # NOT paired in current_year
            year: previous_year
          )
        end

        let!(:older_year_compatible_partnership) do
          create_school_partnership!(
            school:,
            lead_provider:,
            delivery_partner: delivery_partner_alpha, # paired in current_year
            year: older_year
          )
        end

        it "skips the incompatible most-recent year and returns the older compatible partnership" do
          expect(call_service).to eq(older_year_compatible_partnership)
          expect(call_service).not_to eq(previous_year_incompatible_partnership)
        end
      end

      context "when there are gaps between years (non-consecutive year pairing)" do
        let!(:gap_year_compatible_partnership) do
          create_school_partnership!(
            school:,
            lead_provider:,
            delivery_partner: delivery_partner_alpha, # paired in current_year
            year: gap_year
          )
        end

        let!(:previous_year_incompatible_partnership) do
          create_school_partnership!(
            school:,
            lead_provider:,
            delivery_partner: delivery_partner_omega, # NOT paired in current_year
            year: previous_year
          )
        end

        it "returns the most recent previous year with a valid current-year pairing even if years are non-consecutive" do
          expect(call_service).to eq(gap_year_compatible_partnership)
          expect(call_service).not_to eq(previous_year_incompatible_partnership)
        end
      end
    end

    context "when there is no compatible partnership (scenario 3)" do
      before do
        create_school_partnership!(
          school:,
          lead_provider:,
          delivery_partner: delivery_partner_alpha,
          year: previous_year
        )
      end

      it "returns nil when the lead provider is not active this year" do
        expect(call_service).to be_nil
      end

      it "returns nil when the lead provider is active this year but has no delivery partner pairing" do
        find_or_create_active_lead_provider!(lead_provider:, year: current_year)
        expect(call_service).to be_nil
      end

      it "returns nil when the delivery partner is not compatible with this year's pairings" do
        find_or_create_active_lead_provider!(lead_provider:, year: current_year)

        create_lead_provider_delivery_partnership!(
          lead_provider:,
          delivery_partner: delivery_partner_omega,
          year: current_year
        )

        expect(call_service).to be_nil
      end
    end

    context "when both current-year and previous-year partnerships exist" do
      let!(:current_year_school_partnership) do
        create_school_partnership!(
          school:,
          lead_provider:,
          delivery_partner: delivery_partner_alpha,
          year: current_year
        )
      end

      let!(:previous_year_school_partnership) do
        create_school_partnership!(
          school:,
          lead_provider:,
          delivery_partner: delivery_partner_alpha,
          year: previous_year
        )
      end

      it "prefers the current-year partnership (product rule)" do
        expect(call_service).to eq(current_year_school_partnership)
        expect(call_service).not_to eq(previous_year_school_partnership)
      end
    end
  end
end
