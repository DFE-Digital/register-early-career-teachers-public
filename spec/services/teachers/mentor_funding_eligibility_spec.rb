describe Teachers::MentorFundingEligibility do
  subject { Teachers::MentorFundingEligibility.new(trn:) }

  let(:trn) { "1234567" }

  describe 'initialisation with a TRN' do
    context 'when the teacher is present' do
      let!(:teacher) { create(:teacher, trn:) }

      it 'finds the teacher' do
        expect(subject.teacher).to eql(teacher)
      end
    end

    context 'when the teacher is missing' do
      it 'sets the teacher to nil' do
        expect(subject.teacher).to be_nil
      end
    end
  end

  describe 'checking eligibility' do
    context 'when the teacher is missing' do
      it { is_expected.to be_eligible }
    end

    context 'when the teacher has an ineligibility reason and date set' do
      let!(:teacher) { create(:teacher, :ineligible_for_mentor_funding, trn:) }

      it { is_expected.not_to be_eligible }
    end

    context 'when the teacher has no ineligibility reason or date set' do
      let!(:teacher) { create(:teacher, trn:) }

      it { is_expected.to be_eligible }
    end
  end
end
