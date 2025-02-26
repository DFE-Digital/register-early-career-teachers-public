RSpec.describe TeacherHelper, type: :helper do
  let(:teacher) do
    FactoryBot.create(:teacher,
                      trn: '1234567',
                      trs_first_name: 'Barry',
                      trs_last_name: 'White')
  end

  describe '#teacher_full_name' do
    it { expect(teacher_full_name(teacher)).to eq('Barry White') }
  end

  describe '#teacher_trn' do
    it { expect(teacher_trn(teacher)).to eq('TRN: 1234567') }
  end

  describe "#teacher_date_of_birth_hint_text" do
    it { expect(teacher_date_of_birth_hint_text).to eql('For example, 20 4 2001') }
  end

  describe "#teacher_induction_date_hint_text" do
    last_year = Date.current.year.pred

    it { expect(teacher_induction_date_hint_text).to eql("For example, 20 4 #{last_year}") }
  end
end
