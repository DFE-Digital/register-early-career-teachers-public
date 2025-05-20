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
end
