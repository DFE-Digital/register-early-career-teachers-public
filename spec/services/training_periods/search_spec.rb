describe TrainingPeriods::Search do
  let(:result) { described_class.new(order: :started_on).training_periods(**conditions) }

  let(:conditions) { {} }

  context 'when no conditions provided' do
    it 'returns all TrainingPeriods ordered by started_on' do
      expect(result.to_sql).to eq(
        %(SELECT "training_periods".* FROM "training_periods" ORDER BY "training_periods"."started_on" ASC)
      )
    end
  end

  context 'with ect_id condition' do
    let(:conditions) { { ect_id: 123 } }

    it 'filters TrainingPeriods by ect_at_school_period_id' do
      expect(result.to_sql).to include(%(WHERE "training_periods"."ect_at_school_period_id" = 123))
    end
  end

  context 'with no order param' do
    let(:result) { described_class.new.training_periods }

    it 'defaults to ordering by created_at' do
      expect(result.to_sql).to eq(
        %(SELECT "training_periods".* FROM "training_periods" ORDER BY "training_periods"."created_at" ASC)
      )
    end
  end

  describe '#linkable_to_school_partnership' do
    subject(:result) do
      described_class.new.linkable_to_school_partnership(
        school:,
        lead_provider:,
        contract_period:
      )
    end

    let(:school) { FactoryBot.create(:school) }
    let(:lead_provider) { FactoryBot.create(:lead_provider) }
    let(:contract_period) { FactoryBot.create(:contract_period, year: 2025) }
    let(:previous_contract_period) { FactoryBot.create(:contract_period, year: 2024) }

    let(:school_partnership) do
      FactoryBot.create(
        :school_partnership,
        school:,
        lead_provider_delivery_partnership: FactoryBot.create(
          :lead_provider_delivery_partnership,
          active_lead_provider: FactoryBot.create(
            :active_lead_provider,
            lead_provider:,
            contract_period_year: previous_contract_period.year
          )
        )
      )
    end

    let(:ect_at_school_period) do
      FactoryBot.create(:ect_at_school_period,
                        school:,
                        started_on: Date.new(2025, 1, 1),
                        finished_on: Date.new(2025, 12, 31))
    end

    let(:matching_expression_of_interest) do
      FactoryBot.create(
        :active_lead_provider,
        lead_provider:,
        contract_period_year: contract_period.year
      )
    end

    let!(:linkable_tp) do
      FactoryBot.create(:training_period,
                        :with_only_expression_of_interest,
                        ect_at_school_period:,
                        expression_of_interest: matching_expression_of_interest,
                        started_on: Date.new(2025, 3, 1),
                        finished_on: Date.new(2025, 3, 31))
    end

    let!(:already_linked_tp) do
      FactoryBot.create(:training_period,
                        :with_expression_of_interest,
                        ect_at_school_period:,
                        school_partnership:,
                        expression_of_interest: matching_expression_of_interest,
                        started_on: Date.new(2025, 4, 1),
                        finished_on: Date.new(2025, 4, 30))
    end

    let!(:wrong_provider_tp) do
      FactoryBot.create(:training_period,
                        :with_only_expression_of_interest,
                        ect_at_school_period:,
                        expression_of_interest: FactoryBot.create(:active_lead_provider,
                                                                  lead_provider: FactoryBot.create(:lead_provider), # different provider
                                                                  contract_period_year: contract_period.year),
                        started_on: Date.new(2025, 5, 1),
                        finished_on: Date.new(2025, 5, 31))
    end

    let!(:wrong_year_tp) do
      wrong_contract_period = FactoryBot.create(:contract_period, year: 2030)

      FactoryBot.create(:training_period,
                        :with_only_expression_of_interest,
                        ect_at_school_period:,
                        expression_of_interest: FactoryBot.create(:active_lead_provider,
                                                                  lead_provider:,
                                                                  contract_period_year: wrong_contract_period.year),
                        started_on: Date.new(2025, 6, 1),
                        finished_on: Date.new(2025, 6, 30))
    end

    it 'returns only training periods linked to an EOI at the school (no school partnership, matching lead_provider + contract period)' do
      expect(result).to contain_exactly(linkable_tp)
    end
  end
end
