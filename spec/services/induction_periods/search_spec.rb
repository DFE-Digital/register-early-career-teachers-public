describe InductionPeriods::Search do
  let(:result) { described_class.new(order: :started_on).induction_periods(**conditions) }

  let(:conditions) { {} }

  context 'when no conditions provided' do
    it 'returns all InductionPeriods ordered by started_on' do
      expect(result.to_sql).to eq(
        %(SELECT "induction_periods".* FROM "induction_periods" ORDER BY "induction_periods"."started_on" ASC)
      )
    end
  end

  context "with trn condition" do
    let(:conditions) { { trn: "1234567" } }

    it 'filters InductionPeriods by teacher trn' do
      expect(result.to_sql).to include(%(WHERE "teachers"."trn" = '1234567'))
    end
  end

  context 'with no order param' do
    subject(:result) { described_class.new.induction_periods }

    it 'defaults to ordering by created_at' do
      expect(result.to_sql).to eq(
        %(SELECT "induction_periods".* FROM "induction_periods" ORDER BY "induction_periods"."created_at" ASC)
      )
    end
  end
end
