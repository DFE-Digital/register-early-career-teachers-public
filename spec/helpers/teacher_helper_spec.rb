RSpec.describe TeacherHelper, type: :helper do
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: 'Barry', trs_last_name: 'White') }

  describe '#teacher_full_name' do
    it { expect(teacher_full_name(teacher)).to eq('Barry White') }
  end
end
