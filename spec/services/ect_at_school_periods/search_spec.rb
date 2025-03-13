describe ECTAtSchoolPeriods::Search do
  subject { described_class.new.ect_periods(**conditions) }

  context 'when no conditions provided' do
    let(:conditions) { {} }

    it 'returns all the ECTAtSchoolPeriods' do
      expect(subject.to_sql).to eq(%(SELECT "ect_at_school_periods".* FROM "ect_at_school_periods" ORDER BY "ect_at_school_periods"."created_at" ASC))
    end
  end

  context 'with trn conditions' do
    let(:conditions) { { trn: '1234567' } }

    it 'only return ECTAtSchoolPeriods for the teacher with the trn provided' do
      expect(subject.to_sql).to include(%(INNER JOIN "teachers" "teacher" ON "teacher"."id" = "ect_at_school_periods"."teacher_id" WHERE "teacher"."trn" = '1234567'))
    end
  end

  context 'with urn conditions' do
    let(:conditions) { { urn: '123456' } }

    it 'only return ECTAtSchoolPeriods for the school with the urn provided' do
      expect(subject.to_sql).to include(%(INNER JOIN "schools" "school" ON "school"."id" = "ect_at_school_periods"."school_id" WHERE "school"."urn" = 123456))
    end
  end
end
