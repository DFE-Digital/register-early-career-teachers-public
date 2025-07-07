RSpec.describe TeacherHelper, type: :helper do
  let(:teacher) do
    create(:teacher,
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

  describe '#teacher_induction_start_date' do
    context 'when training' do
      before { create(:induction_period, teacher:) }

      it { expect(teacher_induction_start_date(teacher)).to eq(1.year.ago.to_date.to_fs(:govuk)) }
    end

    context 'when not training' do
      it { expect(teacher_induction_start_date(teacher)).to be_nil }
    end
  end

  describe '#teacher_induction_programme' do
    context 'when training' do
      before { create(:induction_period, teacher:) }

      it { expect(teacher_induction_programme(teacher)).to eq('Full induction programme') }
    end

    context 'when not training' do
      it { expect(teacher_induction_programme(teacher)).to be_nil }
    end
  end

  describe '#teacher_induction_ab_name' do
    context 'when training' do
      before { create(:induction_period, teacher:) }

      it { expect(teacher_induction_ab_name(teacher)).to match(/Appropriate Body \d/) }
    end

    context 'when not training' do
      it { expect(teacher_induction_ab_name(teacher)).to be_nil }
    end
  end
end
