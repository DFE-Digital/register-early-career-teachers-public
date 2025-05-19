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

  describe '#current_school' do
    let(:teacher) { FactoryBot.create(:teacher, trn: '1234567') }
    let(:school_1) { FactoryBot.create(:school) }
    let(:school_2) { FactoryBot.create(:school) }

    before do
      FactoryBot.create(:gias_school, school: school_1, name: 'school 1')
      FactoryBot.create(:gias_school, school: school_2, name: 'school 2')

      FactoryBot.create(:ect_at_school_period, teacher:, school: school_1, started_on: Date.new(2023, 1, 10), finished_on: Date.new(2023, 2, 25))
      FactoryBot.create(:ect_at_school_period, teacher:, school: school_2, started_on: Date.new(2023, 7, 11), finished_on: nil)
    end

    it 'returns the school from the latest ECTAtSchoolPeriod ordered by started_on' do
      result = described_class.new.current_school(trn: teacher.trn)
      expect(result).to eq(school_2)
    end

    it 'returns nil if the teacher is not found' do
      result = described_class.new.current_school(trn: 'nonexistent')
      expect(result).to be_nil
    end
  end
end
