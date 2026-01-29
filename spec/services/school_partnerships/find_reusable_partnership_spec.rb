RSpec.describe SchoolPartnerships::FindReusablePartnership do
  subject(:service) { described_class.new }

  let(:school) { FactoryBot.create(:school) }

  let(:lead_provider) { FactoryBot.create(:lead_provider) }

  let(:delivery_partner_alpha) { FactoryBot.create(:delivery_partner) }
  let(:delivery_partner_omega) { FactoryBot.create(:delivery_partner) }

  let(:current_year) { 2025 }
  let(:one_year_ago) { current_year - 1 }
  let(:two_years_ago) { current_year - 2 }
  let(:three_years_ago) { current_year - 3 }

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

    context "when a current-year school partnership exists" do
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
    end

    context "when there is no current-year partnership but a previous partnership is compatible" do
      before do
        create_lead_provider_delivery_partnership!(
          lead_provider:,
          delivery_partner: delivery_partner_alpha,
          year: current_year
        )
      end

      it "returns the most recent compatible previous partnership" do
        one_year_ago_school_partnership =
          create_school_partnership!(
            school:,
            lead_provider:,
            delivery_partner: delivery_partner_alpha,
            year: one_year_ago
          )

        expect(call_service).to eq(one_year_ago_school_partnership)
      end

      context "when multiple prior-year partnerships exist in the same year" do
        let!(:alpha_one_year_ago) do
          create_school_partnership!(
            school:,
            lead_provider:,
            delivery_partner: delivery_partner_alpha,
            year: one_year_ago
          )
        end

        let!(:omega_one_year_ago) do
          create_school_partnership!(
            school:,
            lead_provider:,
            delivery_partner: delivery_partner_omega,
            year: one_year_ago
          )
        end

        it "returns the partnership whose delivery partner is paired this year" do
          result = call_service
          expect(result).to eq(alpha_one_year_ago)
          expect(result).not_to eq(omega_one_year_ago)
        end
      end

      context "when the most recent year is not paired this year but an older one is" do
        let!(:one_year_ago_incompatible_partnership) do
          create_school_partnership!(
            school:,
            lead_provider:,
            delivery_partner: delivery_partner_omega,
            year: one_year_ago
          )
        end

        let!(:two_years_ago_compatible_partnership) do
          create_school_partnership!(
            school:,
            lead_provider:,
            delivery_partner: delivery_partner_alpha,
            year: two_years_ago
          )
        end

        it "skips the incompatible most-recent year and returns the older compatible partnership" do
          expect(call_service).to eq(two_years_ago_compatible_partnership)
          expect(call_service).not_to eq(one_year_ago_incompatible_partnership)
        end
      end

      context "when the most recent compatible partnership is not from the previous year (non-consecutive years)" do
        let!(:three_years_ago_compatible_partnership) do
          create_school_partnership!(
            school:,
            lead_provider:,
            delivery_partner: delivery_partner_alpha,
            year: three_years_ago
          )
        end

        let!(:one_year_ago_incompatible_partnership) do
          create_school_partnership!(
            school:,
            lead_provider:,
            delivery_partner: delivery_partner_omega,
            year: one_year_ago
          )
        end

        it "returns the most recent year with a valid current-year pairing even if years are non-consecutive" do
          expect(call_service).to eq(three_years_ago_compatible_partnership)
          expect(call_service).not_to eq(one_year_ago_incompatible_partnership)
        end
      end
    end

    context "when there is no compatible partnership" do
      before do
        create_school_partnership!(
          school:,
          lead_provider:,
          delivery_partner: delivery_partner_alpha,
          year: one_year_ago
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

    context "when both current-year and prior-year partnerships exist" do
      let!(:current_year_school_partnership) do
        create_school_partnership!(
          school:,
          lead_provider:,
          delivery_partner: delivery_partner_alpha,
          year: current_year
        )
      end

      let!(:one_year_ago_school_partnership) do
        create_school_partnership!(
          school:,
          lead_provider:,
          delivery_partner: delivery_partner_alpha,
          year: one_year_ago
        )
      end

      it "prefers the current-year partnership" do
        expect(call_service).to eq(current_year_school_partnership)
        expect(call_service).not_to eq(one_year_ago_school_partnership)
      end
    end
  end
end
