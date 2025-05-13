RSpec.describe InductionHelper, type: :helper do
  describe '#claiming_body?' do
    let(:teacher) { FactoryBot.create(:teacher) }
    let(:induction_period) { FactoryBot.create(:induction_period, :active, teacher:) }
    let(:other_appropriate_body) { FactoryBot.create(:appropriate_body) }

    it 'returns true when the current induction is with the claiming body' do
      expect(helper.claiming_body?(teacher, induction_period.appropriate_body)).to be true
    end

    it 'returns false when the current induction is with another body' do
      expect(helper.claiming_body?(teacher, other_appropriate_body)).to be false
    end
  end

  describe '#induction_start_date_for' do
    let(:teacher) { FactoryBot.create(:teacher) }

    context 'when the teacher has induction periods' do
      before do
        FactoryBot.create(:induction_period, teacher:, started_on: Date.new(2023, 6, 10), finished_on: Date.new(2023, 9, 30)) # earliest
        FactoryBot.create(:induction_period, teacher:, started_on: Date.new(2023, 10, 1), finished_on: Date.new(2024, 4, 30))
        FactoryBot.create(:induction_period, teacher:, started_on: Date.new(2024, 5, 1), finished_on: Date.new(2024, 6, 30))
      end

      it 'returns the earliest started_on date formatted as GOV.UK date' do
        expect(helper.induction_start_date_for(teacher.trn)).to eq('10 June 2023')
      end
    end

    context 'when the teacher has no induction periods' do
      it 'returns nil' do
        expect(helper.induction_start_date_for(teacher.trn)).to be_nil
      end
    end
  end
end
