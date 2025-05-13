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

  describe '#appropriate_body_name_for' do
    let(:teacher) { FactoryBot.create(:teacher) }
    let!(:older_body) { FactoryBot.create(:appropriate_body, name: 'Older Body') }
    let!(:more_recent_body) { FactoryBot.create(:appropriate_body, name: 'More Recent Body') }

    before do
      FactoryBot.create(:induction_period, started_on: Date.new(2023, 6, 10), finished_on: Date.new(2023, 9, 30), teacher:, appropriate_body: older_body, created_at: 3.months.ago)
      FactoryBot.create(:induction_period, started_on: Date.new(2023, 10, 1), finished_on: Date.new(2024, 4, 30), teacher:, appropriate_body: more_recent_body, created_at: 1.day.ago)
    end

    it 'returns the name of the latest appropriate body by created_at' do
      expect(helper.appropriate_body_name_for(teacher.trn)).to eq('More Recent Body')
    end

    it 'returns nil if no induction periods exist' do
      expect(helper.appropriate_body_name_for('1234567')).to be_nil
    end
  end
end
