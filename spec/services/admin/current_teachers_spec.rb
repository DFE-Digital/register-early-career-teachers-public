describe Admin::CurrentTeachers do
  describe '#current' do
    let(:teacher1) { FactoryBot.create(:teacher) }
    let(:teacher2) { FactoryBot.create(:teacher) }
    let(:teacher3) { FactoryBot.create(:teacher) }
    let(:ab1) { FactoryBot.create(:appropriate_body) }
    let(:ab2) { FactoryBot.create(:appropriate_body) }

    context 'with an appropriate body' do
      before do
        FactoryBot.create(
          :induction_period,
          :active,
          teacher: teacher1,
          appropriate_body: ab1,
          started_on: 1.month.ago.to_date,
          induction_programme: 'fip'
        )
        FactoryBot.create(
          :induction_period,
          :active,
          teacher: teacher2,
          appropriate_body: ab2,
          started_on: 1.month.ago.to_date,
          induction_programme: 'fip'
        )
        FactoryBot.create(
          :induction_period,
          teacher: teacher3,
          appropriate_body: ab1,
          started_on: 2.months.ago.to_date,
          finished_on: 1.month.ago.to_date,
          induction_programme: 'fip'
        )
      end

      it 'returns teachers with ongoing induction periods for the given appropriate bodies' do
        result = described_class.new([ab1.id]).current

        expect(result).to include(teacher1)
        expect(result).not_to include(teacher2)
        expect(result).not_to include(teacher3)
      end
    end

    context 'without an appropriate body' do
      before do
        FactoryBot.create(
          :induction_period,
          :active,
          teacher: teacher1,
          started_on: 1.month.ago.to_date,
          induction_programme: 'fip'
        )
        FactoryBot.create(
          :induction_period,
          teacher: teacher2,
          started_on: 2.months.ago.to_date,
          finished_on: 1.month.ago.to_date,
          induction_programme: 'fip'
        )
      end

      it 'returns all teachers with ongoing induction periods' do
        result = described_class.new([]).current

        expect(result).to include(teacher1)
        expect(result).not_to include(teacher2)
      end
    end

    context 'with multiple periods' do
      before do
        FactoryBot.create(
          :induction_period,
          :active,
          teacher: teacher1,
          appropriate_body: ab1,
          started_on: 1.month.ago.to_date,
          induction_programme: 'fip'
        )

        FactoryBot.create(
          :induction_period,
          teacher: teacher1,
          appropriate_body: ab1,
          started_on: 3.months.ago.to_date,
          finished_on: 2.months.ago.to_date,
          induction_programme: 'fip'
        )
      end

      it 'returns distinct teachers' do
        result = described_class.new([ab1.id]).current

        expect(result.count).to eq(1)
      end
    end
  end
end
