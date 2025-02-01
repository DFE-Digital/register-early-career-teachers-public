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
end
