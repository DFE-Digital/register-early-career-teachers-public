RSpec.describe Admin::Teachers::TrainingPeriods::ChangeContractPeriod::AvailableContractPeriods do
  subject(:available_contract_periods) { described_class.new(training_period:) }

  let(:ect_payments_frozen_year) { nil }
  let(:mentor_payments_frozen_year) { nil }
  let(:teacher) do
    FactoryBot.create(
      :teacher,
      ect_payments_frozen_year:,
      mentor_payments_frozen_year:
    )
  end
  let(:school) { FactoryBot.create(:school) }
  let(:current_contract_period) { FactoryBot.create(:contract_period, year: 2025) }
  let(:target_contract_period) { FactoryBot.create(:contract_period, year: 2026) }
  let(:other_contract_period) { FactoryBot.create(:contract_period, year: 2027) }
  let(:lead_provider) { FactoryBot.create(:lead_provider) }
  let(:delivery_partner) { FactoryBot.create(:delivery_partner) }
  let(:school_partnership) do
    FactoryBot.create(
      :school_partnership,
      :for_year,
      year: current_contract_period.year,
      school:,
      lead_provider:,
      delivery_partner:
    )
  end
  let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, school:) }
  let(:schedule) { FactoryBot.create(:schedule, contract_period: current_contract_period) }
  let(:training_period) do
    FactoryBot.create(
      :training_period,
      :ongoing,
      ect_at_school_period:,
      school_partnership:,
      schedule:
    )
  end

  describe "#contract_periods" do
    let!(:contract_period_2021) { FactoryBot.create(:contract_period, year: 2021, enabled: false) }
    let!(:contract_period_2022) { FactoryBot.create(:contract_period, year: 2022, enabled: false) }
    let!(:disabled_contract_period) { FactoryBot.create(:contract_period, year: 2028, enabled: false) }

    it "returns enabled contract periods excluding the current and frozen years" do
      expect(available_contract_periods.contract_periods).to contain_exactly(target_contract_period, other_contract_period)
    end

    context "when the original frozen contract period is 2021" do
      let(:ect_payments_frozen_year) { contract_period_2021.year }

      it "includes the original disabled frozen contract period and excludes the other disabled years" do
        expect(available_contract_periods.contract_periods)
          .to contain_exactly(contract_period_2021, target_contract_period, other_contract_period)
      end
    end

    context "when the original frozen contract period is 2022" do
      let(:ect_payments_frozen_year) { contract_period_2022.year }

      it "includes the original disabled frozen contract period and excludes the other disabled years" do
        expect(available_contract_periods.contract_periods)
          .to contain_exactly(contract_period_2022, target_contract_period, other_contract_period)
      end
    end

    context "when the training period is for a mentor with an original frozen contract period" do
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing, teacher:, school:) }
      let(:training_period) do
        FactoryBot.create(
          :training_period,
          :ongoing,
          :for_mentor,
          mentor_at_school_period:,
          school_partnership:,
          schedule:
        )
      end

      let(:mentor_payments_frozen_year) { contract_period_2021.year }

      it "uses the mentor frozen year when filtering contract periods" do
        expect(available_contract_periods.contract_periods)
          .to contain_exactly(contract_period_2021, target_contract_period, other_contract_period)
      end
    end

    context "for an EOI only training period" do
      before do
        FactoryBot.create(:active_lead_provider, lead_provider: active_lead_provider.lead_provider, contract_period: target_contract_period)
        FactoryBot.create(:active_lead_provider, contract_period: other_contract_period)
      end

      let(:active_lead_provider) { FactoryBot.create(:active_lead_provider, contract_period: current_contract_period) }
      let(:training_period) do
        FactoryBot.create(
          :training_period,
          :ongoing,
          :with_only_expression_of_interest,
          ect_at_school_period:,
          expression_of_interest: active_lead_provider,
          schedule:
        )
      end

      it "only returns contract periods with an equivalent active lead provider" do
        expect(available_contract_periods.contract_periods).to contain_exactly(target_contract_period)
      end
    end
  end
end
